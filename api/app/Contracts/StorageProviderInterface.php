<?php

namespace App\Contracts;

interface StorageProviderInterface
{
    /**
     * Genera una URL presignada para subida directa (PUT) a R2/S3.
     */
    public function generateUploadUrl(
        string $objectKey,
        string $mimeType = 'image/jpeg',
        int $ttlSeconds = 900
    ): string;

    /**
     * Verifica si el objeto existe en el bucket.
     */
    public function objectExists(string $objectKey): bool;

    /**
     * Genera una URL presignada para descarga/visualización privada.
     */
    public function generateDownloadUrl(
        string $objectKey,
        int $ttlSeconds = 3600
    ): string;

    /**
     * Elimina un objeto del storage.
     */
    public function delete(string $objectKey): bool;
}
