<?php

namespace App\Domain\Evidence;

use App\Contracts\StorageProviderInterface;
use App\Models\Act;
use App\Models\ActEvidence;
use App\Models\AuditLog;
use App\Models\Personero;
use Illuminate\Support\Facades\Request;

class EvidenceService
{
    public function __construct(
        protected StorageProviderInterface $storageProvider
    ) {}

    /**
     * Genera la ruta estructurada y la URL presignada para subida a R2/S3.
     */
    public function generateUploadUrl(
        Act $act,
        string $sha256Hash,
        string $fileMime = 'image/jpeg',
        int $fileSizeBytes = 0,
        int $ttlSeconds = 900
    ): array {
        $stationCode = $act->pollingStation?->code ?? 'mesa';
        $electionId  = $act->election_id ?? 'election';
        $extension   = str_contains($fileMime, 'png') ? 'png' : 'jpg';

        $objectKey = "evidence/election_{$electionId}/station_{$stationCode}/act_{$act->id}/{$sha256Hash}.{$extension}";

        $uploadUrl = $this->storageProvider->generateUploadUrl(
            $objectKey,
            $fileMime,
            $ttlSeconds
        );

        AuditLog::create([
            'user_id'     => auth()->id(),
            'action'      => 'REQUEST_UPLOAD_URL',
            'entity_type' => 'acts',
            'entity_id'   => (string)$act->id,
            'ip_address'  => Request::ip(),
            'user_agent'  => Request::userAgent(),
            'payload'     => [
                'object_key'      => $objectKey,
                'sha256'          => $sha256Hash,
                'file_mime'       => $fileMime,
                'file_size_bytes' => $fileSizeBytes,
            ],
        ]);

        return [
            'upload_url'      => $uploadUrl,
            'object_key'      => $objectKey,
            'storage_provider'=> 'R2',
            'expires_in_sec'  => $ttlSeconds,
        ];
    }

    /**
     * Confirma la evidencia fotográfica subida y la registra en la base de datos.
     */
    public function confirmEvidence(
        Act $act,
        string $objectKey,
        string $sha256Hash,
        string $fileMime,
        int $fileSizeBytes,
        ?int $deviceId = null,
        ?int $widthPx = null,
        ?int $heightPx = null,
        ?string $capturedAt = null
    ): ActEvidence {
        $evidence = ActEvidence::updateOrCreate(
            [
                'act_id'      => $act->id,
                'sha256_hash' => $sha256Hash,
            ],
            [
                'device_id'        => $deviceId,
                'storage_provider' => 'R2',
                'object_key'       => $objectKey,
                'file_mime'        => $fileMime,
                'file_size_bytes'  => $fileSizeBytes,
                'width_px'         => $widthPx,
                'height_px'        => $heightPx,
                'captured_at'      => $capturedAt ?? now(),
            ]
        );

        AuditLog::create([
            'user_id'     => auth()->id(),
            'action'      => 'CONFIRM_EVIDENCE',
            'entity_type' => 'act_evidence',
            'entity_id'   => (string)$evidence->id,
            'ip_address'  => Request::ip(),
            'user_agent'  => Request::userAgent(),
            'payload'     => [
                'act_id'     => $act->id,
                'object_key' => $objectKey,
                'sha256'     => $sha256Hash,
            ],
        ]);

        return $evidence;
    }

    /**
     * Genera una URL de descarga / visualización temporal y privada.
     */
    public function getDownloadUrl(ActEvidence $evidence, int $ttlSeconds = 3600): string
    {
        return $this->storageProvider->generateDownloadUrl($evidence->object_key, $ttlSeconds);
    }
}
