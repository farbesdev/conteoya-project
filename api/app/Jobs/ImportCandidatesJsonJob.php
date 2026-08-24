<?php

namespace App\Jobs;

use App\Models\Candidate;
use App\Models\ElectoralLevel;
use App\Models\ElectoralList;
use App\Models\PoliticalOrganization;
use App\Traits\MigrationSeedingMethod;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ImportCandidatesJsonJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels, MigrationSeedingMethod;

    public int $timeout = 3600; // 1 hora máximo
    public int $tries = 1;

    protected string $filePath;
    protected string $originalFileName;

    public const CACHE_KEY = 'candidates_json_import_progress';

    /**
     * Create a new job instance.
     */
    public function __construct(string $filePath, string $originalFileName = '')
    {
        $this->filePath = $filePath;
        $this->originalFileName = $originalFileName;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        if (!file_exists($this->filePath)) {
            $progress = [
                'status'        => 'failed',
                'error_message' => 'El archivo temporal de importación no existe.',
                'updated_at'    => now()->toIso8601String(),
            ];
            Cache::put(self::CACHE_KEY, $progress, 86400);
            return;
        }

        // 1. Estimar total de registros si es posible
        $progress = [
            'status'             => 'running',
            'file_name'          => $this->originalFileName,
            'total'              => 0,
            'processed'          => 0,
            'new_candidates'     => 0,
            'updated_candidates' => 0,
            'new_lists'          => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> 'Iniciando lectura en streaming...',
            'started_at'         => now()->toIso8601String(),
            'updated_at'         => now()->toIso8601String(),
        ];
        Cache::put(self::CACHE_KEY, $progress, 86400);

        // Pre-cargar niveles electorales
        $election = DB::table('elections')->where('code', 'ERM2026')->first();
        $electionId = $election ? $election->id : 1;

        $levelGov = DB::table('electoral_levels')->where('election_id', $electionId)->where('code', 'REGIONAL_GOBERNADOR')->value('id') ?? 1;
        $levelCons = DB::table('electoral_levels')->where('election_id', $electionId)->where('code', 'REGIONAL_CONSEJERO')->value('id') ?? 2;
        $levelProv = DB::table('electoral_levels')->where('election_id', $electionId)->where('code', 'MUNICIPAL_PROVINCIAL')->value('id') ?? 3;
        $levelDist = DB::table('electoral_levels')->where('election_id', $electionId)->where('code', 'MUNICIPAL_DISTRITAL')->value('id') ?? 4;

        $levelsMap = [
            'REGIONAL'             => $levelGov,
            'GOBERNADOR REGIONAL'  => $levelGov,
            'CONSEJERO REGIONAL'   => $levelCons,
            'MUNICIPAL PROVINCIAL' => $levelProv,
            'MUNICIPAL DISTRITAL'  => $levelDist,
        ];

        // Mapeos en memoria para acelerar resolución O(1)
        $orgMap = DB::table('political_organizations')->pluck('id', 'jee_id')->toArray();
        $listMap = DB::table('electoral_lists')->pluck('id', 'jee_solicitud_id')->toArray();
        $candidateMap = DB::table('candidates')->pluck('id', 'jee_candidate_id')->toArray();
        $candidateDocMap = DB::table('candidates')->whereNotNull('document_number')->pluck('id', 'document_number')->toArray();

        $fp = fopen($this->filePath, 'r');
        if (!$fp) {
            $progress['status'] = 'failed';
            $progress['error_message'] = 'No se pudo abrir el archivo JSON.';
            Cache::put(self::CACHE_KEY, $progress, 86400);
            return;
        }

        $now = now()->toDateTimeString();
        $batchSize = 2000;
        $rawBatch = [];
        $totalProcessed = 0;
        $newCandidatesCount = 0;
        $newListsCount = 0;

        $buffer = '';
        $inObject = false;
        $braceCount = 0;

        try {
            while (!feof($fp)) {
                $chunk = fread($fp, 65536);
                $len = strlen($chunk);

                for ($i = 0; $i < $len; $i++) {
                    $char = $chunk[$i];
                    if ($char === '{') {
                        $inObject = true;
                        $braceCount++;
                    }
                    if ($inObject) {
                        $buffer .= $char;
                    }
                    if ($char === '}') {
                        $braceCount--;
                        if ($braceCount === 0 && $inObject) {
                            $inObject = false;
                            $row = json_decode($buffer, true);
                            $buffer = '';

                            if ($row && is_array($row)) {
                                $rawBatch[] = $row;

                                if (count($rawBatch) >= $batchSize) {
                                    // Comprobar cancelación
                                    $cur = Cache::get(self::CACHE_KEY);
                                    if ($cur && isset($cur['status']) && $cur['status'] === 'canceled') {
                                        fclose($fp);
                                        @unlink($this->filePath);
                                        return;
                                    }

                                    $this->processBatch(
                                        $rawBatch,
                                        $orgMap,
                                        $listMap,
                                        $candidateMap,
                                        $candidateDocMap,
                                        $levelsMap,
                                        $levelGov,
                                        $levelCons,
                                        $now,
                                        $newCandidatesCount,
                                        $newListsCount
                                    );

                                    $totalProcessed += count($rawBatch);
                                    $lastItem = end($rawBatch);
                                    $lastCandidateName = $this->normalizeName($lastItem['strNombreCompleto'] ?? '');

                                    $progress['processed'] = $totalProcessed;
                                    $progress['new_candidates'] = $newCandidatesCount;
                                    $progress['new_lists'] = $newListsCount;
                                    $progress['last_candidate_name'] = $lastCandidateName;
                                    $progress['updated_at'] = now()->toIso8601String();

                                    Cache::put(self::CACHE_KEY, $progress, 86400);
                                    $rawBatch = [];
                                }
                            }
                        }
                    }
                }
            }

            // Procesar lote remanente
            if (!empty($rawBatch)) {
                $this->processBatch(
                    $rawBatch,
                    $orgMap,
                    $listMap,
                    $candidateMap,
                    $candidateDocMap,
                    $levelsMap,
                    $levelGov,
                    $levelCons,
                    $now,
                    $newCandidatesCount,
                    $newListsCount
                );
                $totalProcessed += count($rawBatch);
            }

            fclose($fp);
            @unlink($this->filePath);

            $progress['status'] = 'completed';
            $progress['total'] = $totalProcessed;
            $progress['processed'] = $totalProcessed;
            $progress['new_candidates'] = $newCandidatesCount;
            $progress['new_lists'] = $newListsCount;
            $progress['percentage'] = 100.0;
            $progress['last_candidate_name'] = 'Importación completada exitosamente';
            $progress['updated_at'] = now()->toIso8601String();

            Cache::put(self::CACHE_KEY, $progress, 86400);

        } catch (\Throwable $e) {
            if (is_resource($fp)) {
                fclose($fp);
            }
            @unlink($this->filePath);

            Log::error("Error en ImportCandidatesJsonJob: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            $progress['status'] = 'failed';
            $progress['error_message'] = 'Error durante la importación: ' . $e->getMessage();
            $progress['updated_at'] = now()->toIso8601String();
            Cache::put(self::CACHE_KEY, $progress, 86400);
        }
    }

    /**
     * Procesa un lote de registros (Organizaciones, Listas, Candidatos, Candidacias)
     */
    protected function processBatch(
        array $batch,
        array &$orgMap,
        array &$listMap,
        array &$candidateMap,
        array &$candidateDocMap,
        array $levelsMap,
        int $levelGov,
        int $levelCons,
        string $now,
        int &$newCandidatesCount,
        int &$newListsCount
    ): void {
        $orgsToInsert = [];
        $listsToInsert = [];
        $candidatesToInsert = [];
        $candidaciesToInsert = [];

        // 1. Organizaciones Políticas
        foreach ($batch as $r) {
            $orgJeeId = $r['idOrganizacionPolitica'] ?? null;
            if ($orgJeeId && !isset($orgMap[$orgJeeId]) && !isset($orgsToInsert[$orgJeeId])) {
                $orgName = trim($r['strOrganizacionPolitica'] ?? '');
                $orgType = trim($r['strTipoOrgPolitica'] ?? 'PARTIDO POLÍTICO');
                $logoUrl = "https://stovotoinformadodev.blob.core.windows.net/contenedor-2/{$orgJeeId}.png";

                $orgsToInsert[$orgJeeId] = [
                    'jee_id'     => $orgJeeId,
                    'name'       => $orgName,
                    'short_name' => null,
                    'org_type'   => $orgType,
                    'logo_url'   => $logoUrl,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        if (!empty($orgsToInsert)) {
            $this->batchInsertOrUpdate(
                'political_organizations',
                ['jee_id', 'name', 'short_name', 'org_type', 'logo_url', 'created_at', 'updated_at'],
                array_values($orgsToInsert),
                ['matchColumns' => ['jee_id'], 'updateColumns' => ['name', 'org_type', 'logo_url', 'updated_at'], 'verbose' => false]
            );
            $orgMap = DB::table('political_organizations')->pluck('id', 'jee_id')->toArray();
        }

        // 2. Listas Electorales
        foreach ($batch as $r) {
            $expStr = trim($r['strCodExpedienteExt'] ?? '');
            $solicitudId = $this->extractSolicitudId($expStr);
            $orgJeeId = $r['idOrganizacionPolitica'] ?? null;
            $orgId = $orgMap[$orgJeeId] ?? null;

            if ($solicitudId && $orgId && !isset($listMap[$solicitudId]) && !isset($listsToInsert[$solicitudId])) {
                $type = strtoupper(trim($r['strTipoEleccion'] ?? 'MUNICIPAL DISTRITAL'));
                $ubigeo = trim($r['strUbigeoPostula'] ?? '');
                $cargo = strtoupper(trim($r['strCargoEleccion'] ?? ''));

                $depCode = null;
                $provCode = null;
                $distCode = null;

                if (strlen($ubigeo) >= 2) $depCode = substr($ubigeo, 0, 2);
                if (strlen($ubigeo) >= 4 && substr($ubigeo, 2, 2) !== '00') $provCode = substr($ubigeo, 0, 4);
                if (strlen($ubigeo) >= 6 && substr($ubigeo, 4, 2) !== '00') $distCode = substr($ubigeo, 0, 6);

                if ($type === 'REGIONAL' || $type === 'GOBERNADOR REGIONAL') {
                    $provCode = null;
                    $distCode = null;
                    $levelId = ($cargo === 'GOBERNADOR REGIONAL' || $cargo === 'VICEGOBERNADOR REGIONAL') ? $levelGov : $levelCons;
                } elseif ($type === 'MUNICIPAL PROVINCIAL') {
                    $distCode = null;
                    $levelId = $levelsMap['MUNICIPAL PROVINCIAL'];
                } else {
                    $levelId = $levelsMap['MUNICIPAL DISTRITAL'];
                }

                $listsToInsert[$solicitudId] = [
                    'jee_solicitud_id'          => $solicitudId,
                    'political_organization_id' => $orgId,
                    'electoral_level_id'        => $levelId,
                    'department_code'           => $depCode,
                    'province_code'             => $provCode,
                    'district_code'             => $distCode,
                    'status'                    => strtoupper(trim($r['strEstado'] ?? 'INSCRITO')),
                    'created_at'                => $now,
                    'updated_at'                => $now,
                ];
                $newListsCount++;
            }
        }

        if (!empty($listsToInsert)) {
            $this->batchInsertOrUpdate(
                'electoral_lists',
                ['jee_solicitud_id', 'political_organization_id', 'electoral_level_id', 'department_code', 'province_code', 'district_code', 'status', 'created_at', 'updated_at'],
                array_values($listsToInsert),
                ['matchColumns' => ['jee_solicitud_id'], 'updateColumns' => ['status', 'updated_at'], 'verbose' => false]
            );
            $listMap = DB::table('electoral_lists')->pluck('id', 'jee_solicitud_id')->toArray();
        }

        // 3. Candidatos (Personas)
        $candidatesToUpsert = [];
        foreach ($batch as $r) {
            $dni = trim($r['strDocumentoIdentidad'] ?? '');
            if (!$dni) continue;

            $fullName = $this->normalizeName($r['strNombreCompleto'] ?? '');
            $photoUrl = "https://stovotoinformadodev.blob.core.windows.net/contenedor-1/{$dni}.jpg";
            $jeeCandId = is_numeric($dni) ? (int)$dni : null;

            if (!isset($candidateDocMap[$dni]) && !isset($candidatesToUpsert[$dni])) {
                $newCandidatesCount++;
            }

            $candidatesToUpsert[$dni] = [
                'jee_candidate_id' => $jeeCandId,
                'id_hoja_vida'     => $dni,
                'document_number'  => $dni,
                'full_name'        => $fullName,
                'photo_url'        => $photoUrl,
                'local_photo_url'  => null,
                'created_at'       => $now,
                'updated_at'       => $now,
            ];
        }

        if (!empty($candidatesToUpsert)) {
            $this->batchInsertOrUpdate(
                'candidates',
                ['jee_candidate_id', 'id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'created_at', 'updated_at'],
                array_values($candidatesToUpsert),
                ['matchColumns' => ['document_number'], 'updateColumns' => ['full_name', 'photo_url', 'updated_at'], 'verbose' => false]
            );
            $candidateDocMap = DB::table('candidates')->whereNotNull('document_number')->pluck('id', 'document_number')->toArray();
        }

        // 4. Candidacias (Candidacies vinculadas a electoral_lists y candidates)
        foreach ($batch as $r) {
            $expStr = trim($r['strCodExpedienteExt'] ?? '');
            $solicitudId = $this->extractSolicitudId($expStr);
            $dni = trim($r['strDocumentoIdentidad'] ?? '');

            $electoralListId = $listMap[$solicitudId] ?? null;
            $candidateId = $candidateDocMap[$dni] ?? null;

            if ($electoralListId && $candidateId) {
                $position = strtoupper(trim($r['strCargoEleccion'] ?? 'CANDIDATO'));
                $listNumber = (int) ($r['idPosicion'] ?? 0);
                $status = strtoupper(trim($r['strEstadoPersona'] ?? ($r['strEstado'] ?? 'INSCRITO')));

                $candidaciesToInsert[] = [
                    'electoral_list_id' => $electoralListId,
                    'candidate_id'      => $candidateId,
                    'position'          => $position,
                    'list_number'       => $listNumber,
                    'status'            => $status,
                    'created_at'        => $now,
                    'updated_at'        => $now,
                ];
            }
        }

        if (!empty($candidaciesToInsert)) {
            $this->batchInsertOrUpdate(
                'candidacies',
                ['electoral_list_id', 'candidate_id', 'position', 'list_number', 'status', 'created_at', 'updated_at'],
                $candidaciesToInsert,
                ['matchColumns' => ['electoral_list_id', 'candidate_id'], 'updateColumns' => ['position', 'list_number', 'status', 'updated_at'], 'verbose' => false]
            );
        }
    }

    protected function normalizeName(string $name): string
    {
        $clean = preg_replace('/[-_]+/', ' ', $name);
        return trim(preg_replace('/\s+/', ' ', $clean));
    }

    protected function extractSolicitudId(string $exp): int
    {
        $digits = preg_replace('/\D/', '', $exp);
        return $digits !== '' ? (int)$digits : 0;
    }
}
