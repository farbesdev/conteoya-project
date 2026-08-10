<?php

namespace App\Domain\Acts;

use App\Contracts\ActRecognitionProviderInterface;
use App\Domain\Acts\DTOs\ActExtractionResult;
use App\Models\Act;
use App\Models\ActEvidence;
use App\Models\AuditLog;
use App\Models\OcrAiExtraction;
use Illuminate\Support\Facades\Request;

class ActRecognitionService
{
    public function __construct(
        protected ActRecognitionProviderInterface $provider
    ) {}

    public function recognize(
        string $imagePath,
        string $mimeType = 'image/jpeg',
        ?Act $act = null,
        ?ActEvidence $evidence = null,
        array $context = []
    ): ActExtractionResult {
        // Ejecutar extracción a través del provider
        $result = $this->provider->extract($imagePath, $mimeType, $context);

        // Si hay un acta o evidencia asociada, guardar para auditoría y trazabilidad
        if ($act) {
            OcrAiExtraction::create([
                'act_id'              => $act->id,
                'act_evidence_id'     => $evidence?->id,
                'provider_name'       => $result->providerName,
                'raw_response_json'   => $result->rawResponse,
                'extracted_data_json' => $result->toArray(),
                'processed_at'        => now(),
            ]);

            AuditLog::create([
                'user_id'     => auth()->id(),
                'action'      => 'OCR_AI_RECOGNITION',
                'entity_type' => 'acts',
                'entity_id'   => (string)$act->id,
                'ip_address'  => Request::ip(),
                'user_agent'  => Request::userAgent(),
                'payload'     => [
                    'provider'           => $result->providerName,
                    'has_low_confidence' => $result->hasLowConfidenceFields(),
                ],
            ]);
        }

        return $result;
    }
}
