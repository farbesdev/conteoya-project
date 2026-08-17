# 03 — Guía: Ingesta de Actas Electorales

> **Guía:** How-To Operativo  
> **Tema:** Ingesta de Actas e Idempotencia

---

## 1. Registro Manual / Offline de un Acta Electoral

Para registrar un acta electoral de forma atómica y protegida por idempotencia:

### Endpoint
`POST /api/v1/acts`

### Headers
```http
Authorization: Bearer {token_sanctum}
Content-Type: application/json
Idempotency-Key: {UUID_generado_en_cliente}
```

### Request Body (JSON)
```json
{
  "client_operation_id": "550e8400-e29b-41d4-a716-446655440000",
  "polling_station_code": "030390",
  "election_id": 1,
  "electoral_level_id": 1,
  "act_code": "ACT-030390-REG",
  "status": "DRAFT",
  "totals": {
    "registered_voters": 300,
    "voters_who_voted": 280,
    "total_votes": 280,
    "blank_votes": 10,
    "null_votes": 5,
    "challenged_votes": 0
  },
  "results": [
    {
      "political_organization_id": 4,
      "votes": 150,
      "source": "MANUAL"
    },
    {
      "political_organization_id": 14,
      "votes": 115,
      "source": "MANUAL"
    }
  ]
}
```

---

## 2. Confirmación del Acta

Una vez que el personero ha verificado todos los campos:

### Endpoint
`POST /api/v1/acts/{act_id}/confirm`

### Response `200 OK`
```json
{
  "message": "Acta electoral confirmada exitosamente.",
  "data": {
    "id": 1,
    "status": "CONFIRMED",
    "confirmed_at": "2026-10-04T19:30:00Z"
  }
}
```
