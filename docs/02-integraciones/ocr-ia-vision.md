# 02 — Integración: Visión Artificial y OCR (Human-in-the-Loop)

> **Integración:** Reconocimiento Asistido de Actas  
> **Patrón:** Adapter Pattern · Human-in-the-Loop

---

## 1. El Principio Human-in-the-Loop

En **ConteoYA**, la inteligencia artificial y los motores de OCR actúan exclusivamente como **herramientas de asistencia al personero**, nunca como autoridades finales de confirmación:

- **Propuesta:** La IA analiza la imagen del acta y propone un desglose de votos por lista junto con un índice de confianza (`confidence: 0.00 - 1.00`).
- **Estado Inicial:** Toda acta generada mediante asistencia por OCR/IA queda en estado preliminar `DRAFT`.
- **Validación Humana:** El personero de mesa debe contrastar en pantalla los valores reconocidos contra el acta física y presionar el botón de confirmación explícito (`CONFIRM`).

---

## 2. Contrato de Reconocimiento (`ActRecognitionService`)

La arquitectura desacopla el proveedor de OCR mediante la interfaz `ActRecognitionServiceInterface`:

```php
interface ActRecognitionServiceInterface
{
    public function extractFromImage(string $imageBinaryOrUrl): ActRecognitionResultDTO;
}
```

Esto permite alternar sin romper el código entre Google Cloud Vision, Azure Computer Vision, AWS Textract o modelos multimodales locales/on-premise.
