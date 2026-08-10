<?php

namespace App\Infrastructure\Storage;

use App\Contracts\StorageProviderInterface;
use Illuminate\Support\Facades\Storage;

class R2StorageProvider implements StorageProviderInterface
{
    protected string $diskName;

    public function __construct(string $diskName = 'r2')
    {
        $this->diskName = $diskName;
    }

    public function generateUploadUrl(
        string $objectKey,
        string $mimeType = 'image/jpeg',
        int $ttlSeconds = 900
    ): string {
        $disk = Storage::disk($this->diskName);

        if (method_exists($disk, 'temporaryUploadUrl')) {
            return $disk->temporaryUploadUrl(
                $objectKey,
                now()->addSeconds($ttlSeconds),
                ['ContentType' => $mimeType]
            );
        }

        // Fallback para storage compatible con temporaryUrl
        return $disk->temporaryUrl(
            $objectKey,
            now()->addSeconds($ttlSeconds)
        );
    }

    public function objectExists(string $objectKey): bool
    {
        return Storage::disk($this->diskName)->exists($objectKey);
    }

    public function generateDownloadUrl(string $objectKey, int $ttlSeconds = 3600): string
    {
        return Storage::disk($this->diskName)->temporaryUrl(
            $objectKey,
            now()->addSeconds($ttlSeconds)
        );
    }

    public function delete(string $objectKey): bool
    {
        return Storage::disk($this->diskName)->delete($objectKey);
    }
}
