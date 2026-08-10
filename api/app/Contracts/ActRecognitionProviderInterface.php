<?php

namespace App\Contracts;

use App\Domain\Acts\DTOs\ActExtractionResult;

interface ActRecognitionProviderInterface
{
    /**
     * Procesa una imagen de acta y devuelve la extracción estructurada.
     *
     * @param string $imagePath Ruta o URL de la imagen
     * @param string $mimeType MIME type de la imagen
     * @param array $context Contexto electoral opcional (listas de candidatos, mesa, etc.)
     * @return ActExtractionResult
     */
    public function extract(string $imagePath, string $mimeType = 'image/jpeg', array $context = []): ActExtractionResult;

    /**
     * Nombre identificador del proveedor.
     */
    public function getName(): string;
}
