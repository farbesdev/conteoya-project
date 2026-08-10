<?php

namespace App\Infrastructure\Storage;

use App\Contracts\StorageProviderInterface;

class MockStorageProvider implements StorageProviderInterface
{
    protected array $storedObjects = [];

    public function generateUploadUrl(
        string $objectKey,
        string $mimeType = 'image/jpeg',
        int $ttlSeconds = 900
    ): string {
        $expires = time() + $ttlSeconds;
        return "https://mock-r2.conteoya.pe/upload/{$objectKey}?expires={$expires}&mime=" . urlencode($mimeType);
    }

    public function objectExists(string $objectKey): bool
    {
        // En testing o mock, se considera válido si está en la lista o por defecto true
        return $this->storedObjects[$objectKey] ?? true;
    }

    public function markAsExists(string $objectKey, bool $exists = true): void
    {
        $this->storedObjects[$objectKey] = $exists;
    }

    public function generateDownloadUrl(string $objectKey, int $ttlSeconds = 3600): string
    {
        $expires = time() + $ttlSeconds;
        return "https://mock-r2.conteoya.pe/download/{$objectKey}?expires={$expires}";
    }

    public function delete(string $objectKey): bool
    {
        unset($this->storedObjects[$objectKey]);
        return true;
    }
}
