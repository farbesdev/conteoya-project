<?php

namespace App\Infrastructure\Ocr;

use App\Contracts\ActRecognitionProviderInterface;
use App\Domain\Acts\DTOs\ActExtractionResult;
use App\Domain\Acts\DTOs\ExtractionFieldConfidence;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiVisionProvider implements ActRecognitionProviderInterface
{
    public function __construct(
        protected ?string $apiKey = null,
        protected string $model = 'gemini-1.5-flash'
    ) {
        $this->apiKey = $apiKey ?? config('services.gemini.api_key', env('GEMINI_API_KEY'));
    }

    public function extract(string $imagePath, string $mimeType = 'image/jpeg', array $context = []): ActExtractionResult
    {
        if (empty($this->apiKey)) {
            Log::warning("Gemini API Key no configurada. Usando fallback Mock provider.");
            $mock = new MockActRecognitionProvider();
            return $mock->extract($imagePath, $mimeType, $context);
        }

        $base64Image = file_exists($imagePath)
            ? base64_encode(file_get_contents($imagePath))
            : $imagePath;

        $prompt = "Eres un asistente de digitalización electoral del Perú. Extrae los resultados del acta electoral en formato JSON con las claves: "
            . "polling_station_code, registered_voters, voters_who_voted, total_votes, blank_votes, null_votes, challenged_votes, "
            . "results (array con political_organization_id, votes, confidence), y field_confidence (objeto con score 0.0-1.0 por campo).";

        try {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:generateContent?key={$this->apiKey}";
            $response = Http::timeout(30)->post($url, [
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $prompt],
                            [
                                'inlineData' => [
                                    'mimeType' => $mimeType,
                                    'data' => $base64Image,
                                ],
                            ],
                        ],
                    ],
                ],
                'generationConfig' => [
                    'responseMimeType' => 'application/json',
                ],
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $text = $data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
                $content = json_decode($text, true);

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
            Log::error("Error en Gemini Vision Act Recognition: " . $e->getMessage());
        }

        $mock = new MockActRecognitionProvider();
        return $mock->extract($imagePath, $mimeType, $context);
    }

    public function getName(): string
    {
        return 'GEMINI_VISION';
    }
}
