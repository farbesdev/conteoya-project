<?php

namespace App\Infrastructure\Ocr;

use App\Contracts\ActRecognitionProviderInterface;
use App\Domain\Acts\DTOs\ActExtractionResult;
use App\Domain\Acts\DTOs\ExtractionFieldConfidence;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OpenAiVisionProvider implements ActRecognitionProviderInterface
{
    public function __construct(
        protected ?string $apiKey = null,
        protected string $model = 'gpt-4o'
    ) {
        $this->apiKey = $apiKey ?? config('services.openai.api_key', env('OPENAI_API_KEY'));
    }

    public function extract(string $imagePath, string $mimeType = 'image/jpeg', array $context = []): ActExtractionResult
    {
        if (empty($this->apiKey)) {
            Log::warning("OpenAI API Key no configurada. Usando fallback Mock provider.");
            $mock = new MockActRecognitionProvider();
            return $mock->extract($imagePath, $mimeType, $context);
        }

        // Si la imagen es una ruta local, convertir a base64
        $base64Image = file_exists($imagePath)
            ? base64_encode(file_get_contents($imagePath))
            : $imagePath;

        $prompt = "Eres un asistente experto en reconocimiento de actas electorales del Perú (ERM 2026). "
            . "Extrae los datos numéricos y estructurados del acta adjunta: mesa, electores hábiles, ciudadanos que votaron, "
            . "votos por organización política, votos en blanco, nulos, impugnados y total de votos emitidos. "
            . "Devuelve estrictamente un JSON con las claves: polling_station_code, registered_voters, voters_who_voted, "
            . "total_votes, blank_votes, null_votes, challenged_votes, results: [{political_organization_id, votes, confidence}], "
            . "field_confidence: {polling_station_code: 0.99, ...}";

        try {
            $response = Http::withToken($this->apiKey)
                ->timeout(30)
                ->post('https://api.openai.com/v1/chat/completions', [
                    'model' => $this->model,
                    'response_format' => ['type' => 'json_object'],
                    'messages' => [
                        [
                            'role' => 'user',
                            'content' => [
                                ['type' => 'text', 'text' => $prompt],
                                [
                                    'type' => 'image_url',
                                    'image_url' => [
                                        'url' => "data:{$mimeType};base64,{$base64Image}",
                                    ],
                                ],
                            ],
                        ],
                    ],
                ]);

            if ($response->successful()) {
                $data = $response->json();
                $content = json_decode($data['choices'][0]['message']['content'] ?? '{}', true);

                $confidenceMap = [];
                foreach ($content['field_confidence'] ?? [] as $field => $conf) {
                    $confidenceMap[] = new ExtractionFieldConfidence(
                        $field,
                        $content[$field] ?? null,
                        (float)$conf,
                        (float)$conf < 0.85
                    );
                }

                return new ActExtractionResult(
                    providerName: $this->getName(),
                    pollingStationCode: $content['polling_station_code'] ?? null,
                    registeredVoters: $content['registered_voters'] ?? null,
                    votersWhoVoted: $content['voters_who_voted'] ?? null,
                    totalVotes: $content['total_votes'] ?? null,
                    blankVotes: $content['blank_votes'] ?? 0,
                    nullVotes: $content['null_votes'] ?? 0,
                    challengedVotes: $content['challenged_votes'] ?? 0,
                    results: $content['results'] ?? [],
                    confidenceMap: $confidenceMap,
                    rawResponse: $data,
                    processedAt: now()->toIso8601String()
                );
            }
        } catch (\Throwable $e) {
            Log::error("Error en OpenAI Vision Act Recognition: " . $e->getMessage());
        }

        // Fallback en caso de error
        $mock = new MockActRecognitionProvider();
        return $mock->extract($imagePath, $mimeType, $context);
    }

    public function getName(): string
    {
        return 'OPENAI_VISION';
    }
}
