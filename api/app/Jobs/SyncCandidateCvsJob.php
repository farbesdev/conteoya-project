<?php

namespace App\Jobs;

use App\Models\Candidate;
use App\Models\CandidateCv;
use App\Services\JneHojaVidaService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class SyncCandidateCvsJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 7200; // 2 horas máximo por ejecución
    public int $tries = 3;

    protected int $chunkSize;
    protected int $delayMs;
    protected ?int $maxLimit;

    public const CACHE_KEY = 'candidate_cv_sync_progress';

    /**
     * Create a new job instance.
     */
    public function __construct(int $chunkSize = 50, int $delayMs = 250, ?int $maxLimit = null)
    {
        $this->chunkSize = $chunkSize;
        $this->delayMs = $delayMs;
        $this->maxLimit = $maxLimit;
    }

    /**
     * Execute the job.
     */
    public function handle(JneHojaVidaService $cvService): void
    {
        $query = Candidate::whereNotNull('id_hoja_vida')
            ->where('id_hoja_vida', '!=', '');

        $total = $this->maxLimit ? min($query->count(), $this->maxLimit) : $query->count();

        // Inicializar estado en Cache / Redis
        $progress = [
            'status'             => 'running',
            'total'              => $total,
            'processed'          => 0,
            'success_count'      => 0,
            'error_count'        => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> '',
            'started_at'         => now()->toIso8601String(),
            'updated_at'         => now()->toIso8601String(),
        ];

        Cache::put(self::CACHE_KEY, $progress, 86400);

        $processed = 0;
        $successCount = 0;
        $errorCount = 0;

        $candidateQuery = $query->orderBy('id');
        if ($this->maxLimit) {
            $candidateQuery->limit($this->maxLimit);
        }

        $candidateQuery->chunk($this->chunkSize, function ($candidates) use ($cvService, &$processed, &$successCount, &$errorCount, $total) {
            // Verificar si el usuario solicitó cancelar/pausar la sincronización
            $currentStatus = Cache::get(self::CACHE_KEY);
            if (isset($currentStatus['status']) && $currentStatus['status'] === 'canceled') {
                Log::info("Sincronización de Hojas de Vida cancelada por el usuario.");
                return false; // Rompe el chunk loop
            }

            foreach ($candidates as $candidate) {
                try {
                    $cvData = $cvService->fetchCandidateCv((string) $candidate->id_hoja_vida);

                    if ($cvData) {
                        CandidateCv::updateOrCreate(
                            ['id_hoja_vida' => (string) $candidate->id_hoja_vida],
                            [
                                'candidate_id'         => $candidate->id,
                                'general_data'         => $cvData['general_data'] ?? null,
                                'academic_data'        => $cvData['academic_data'] ?? null,
                                'work_experience'      => $cvData['work_experience'] ?? null,
                                'political_trajectory' => $cvData['political_trajectory'] ?? null,
                                'sworn_declaration'    => $cvData['sworn_declaration'] ?? null,
                                'penal_sentences'      => $cvData['penal_sentences'] ?? null,
                                'additional_info'      => $cvData['additional_info'] ?? null,
                            ]
                        );
                        $successCount++;
                    } else {
                        $errorCount++;
                    }
                } catch (\Throwable $e) {
                    $errorCount++;
                    Log::warning("Error procesando CV candidato {$candidate->id} ({$candidate->id_hoja_vida}): " . $e->getMessage());
                }

                $processed++;

                // Pausa configurada para evitar rate limiting (WAF / HTTP 429)
                if ($this->delayMs > 0) {
                    usleep($this->delayMs * 1000);
                }

                // Actualizar métricas cada 5 candidatos procesados
                if ($processed % 5 === 0 || $processed === $total) {
                    $percentage = $total > 0 ? round(($processed / $total) * 100, 2) : 100;
                    Cache::put(self::CACHE_KEY, [
                        'status'             => 'running',
                        'total'              => $total,
                        'processed'          => $processed,
                        'success_count'      => $successCount,
                        'error_count'        => $errorCount,
                        'percentage'         => $percentage,
                        'last_candidate_name'=> $candidate->full_name,
                        'started_at'         => Cache::get(self::CACHE_KEY)['started_at'] ?? now()->toIso8601String(),
                        'updated_at'         => now()->toIso8601String(),
                    ], 86400);
                }
            }
        });

        // Marcar finalización
        $finalStatus = Cache::get(self::CACHE_KEY);
        if ($finalStatus && $finalStatus['status'] !== 'canceled') {
            Cache::put(self::CACHE_KEY, [
                'status'             => 'completed',
                'total'              => $total,
                'processed'          => $processed,
                'success_count'      => $successCount,
                'error_count'        => $errorCount,
                'percentage'         => 100.0,
                'last_candidate_name'=> 'Sincronización finalizada con éxito.',
                'started_at'         => $finalStatus['started_at'] ?? now()->toIso8601String(),
                'updated_at'         => now()->toIso8601String(),
                'completed_at'       => now()->toIso8601String(),
            ], 86400);
        }
    }

    /**
     * Manejo de fallo del Job
     */
    public function failed(\Throwable $exception): void
    {
        Log::error("Fallo crítico en SyncCandidateCvsJob: " . $exception->getMessage());
        $current = Cache::get(self::CACHE_KEY, []);
        $current['status'] = 'failed';
        $current['error_message'] = $exception->getMessage();
        $current['updated_at'] = now()->toIso8601String();
        Cache::put(self::CACHE_KEY, $current, 86400);
    }
}
