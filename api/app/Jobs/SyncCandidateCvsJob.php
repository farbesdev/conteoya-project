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

        $csvDir = base_path('../database/files');
        if (!file_exists($csvDir)) {
            @mkdir($csvDir, 0755, true);
        }
        $csvPath = $csvDir . '/candidate_cvs.csv';

        // Si el archivo CSV no existe, crearlo con sus cabeceras
        if (!file_exists($csvPath)) {
            $fp = @fopen($csvPath, 'w');
            if ($fp) {
                fputcsv($fp, [
                    'id_hoja_vida',
                    'candidate_id',
                    'general_data',
                    'academic_data',
                    'work_experience',
                    'political_trajectory',
                    'sworn_declaration',
                    'penal_sentences',
                    'additional_info',
                ]);
                fclose($fp);
            }
        }

        $candidateQuery->chunk($this->chunkSize, function ($candidates) use ($cvService, &$processed, &$successCount, &$errorCount, $total, $csvPath) {
            // Verificar si el usuario solicitó cancelar/pausar la sincronización
            $currentStatus = Cache::get(self::CACHE_KEY);
            if (isset($currentStatus['status']) && $currentStatus['status'] === 'canceled') {
                Log::info("Sincronización de Hojas de Vida cancelada por el usuario.");
                return false; // Rompe el chunk loop
            }

            $csvFile = @fopen($csvPath, 'a');

            foreach ($candidates as $candidate) {
                try {
                    $cvData = $cvService->fetchCandidateCv((string) $candidate->id_hoja_vida);

                    if ($cvData) {
                        $genData    = isset($cvData['general_data']) ? json_encode($cvData['general_data'], JSON_UNESCAPED_UNICODE) : null;
                        $acadData   = isset($cvData['academic_data']) ? json_encode($cvData['academic_data'], JSON_UNESCAPED_UNICODE) : null;
                        $workExp    = isset($cvData['work_experience']) ? json_encode($cvData['work_experience'], JSON_UNESCAPED_UNICODE) : null;
                        $polTraj    = isset($cvData['political_trajectory']) ? json_encode($cvData['political_trajectory'], JSON_UNESCAPED_UNICODE) : null;
                        $swornDecl  = isset($cvData['sworn_declaration']) ? json_encode($cvData['sworn_declaration'], JSON_UNESCAPED_UNICODE) : null;
                        $penalSent  = isset($cvData['penal_sentences']) ? json_encode($cvData['penal_sentences'], JSON_UNESCAPED_UNICODE) : null;
                        $addInfo    = isset($cvData['additional_info']) ? (is_string($cvData['additional_info']) ? $cvData['additional_info'] : json_encode($cvData['additional_info'], JSON_UNESCAPED_UNICODE)) : null;

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

                        // Descargar y convertir foto localmente si aún no existe
                        if (empty($candidate->local_photo_url) && !empty($candidate->photo_url)) {
                            $docNumber = $candidate->id_hoja_vida ?: ('JEE_' . $candidate->jee_candidate_id);
                            $filename = "$docNumber/foto.webp";
                            $disk = \Illuminate\Support\Facades\Storage::disk('candidates');

                            if (!$disk->exists($filename)) {
                                try {
                                    $rawContent = @file_get_contents($candidate->photo_url);
                                    if ($rawContent !== false && $rawContent !== '') {
                                        $image = @imagecreatefromstring($rawContent);
                                        if ($image !== false) {
                                            ob_start();
                                            imagewebp($image, null, 85);
                                            $webpData = ob_get_clean();
                                            imagedestroy($image);

                                            $disk->put($filename, $webpData);
                                            $candidate->update(['local_photo_url' => $filename]);
                                        }
                                    }
                                } catch (\Throwable $imgEx) {
                                    Log::warning("Error descargando foto para candidato {$candidate->id}: " . $imgEx->getMessage());
                                }
                            } else {
                                $candidate->update(['local_photo_url' => $filename]);
                            }
                        }

                        // Escribir fila en el archivo CSV para backup y futuras ejecuciones de Seeders
                        if ($csvFile) {
                            fputcsv($csvFile, [
                                (string) $candidate->id_hoja_vida,
                                (string) $candidate->id,
                                $genData,
                                $acadData,
                                $workExp,
                                $polTraj,
                                $swornDecl,
                                $penalSent,
                                $addInfo,
                            ]);
                        }

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

            if ($csvFile) {
                fclose($csvFile);
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
