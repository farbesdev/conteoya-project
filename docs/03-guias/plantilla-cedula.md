# 03 — Guía: Plantilla de Cédula por Mesa de Sufragio

> **Guía:** How-To Operativo  
> **Tema:** Consulta y Precarga del Formulario de Votación

---

## 1. Propósito

Permite a la aplicación móvil o interfaz web consultar en un único round-trip todos los datos de la mesa, el nivel de elección, las organizaciones políticas en contienda y sus candidatos ordenados, resolviendo el ubigeo sin necesidad de que la mesa cuente con un registro en `electoral_locations`.

---

## 2. Petición HTTP

### Endpoint
`GET /api/v1/ballot-template`

### Parámetros de Consulta (Query Params)
- `polling_station_code`: Código de la mesa de 6 dígitos (ej. `030390`).
- `electoral_level_id`: ID del nivel electoral (ej. `1` para Regional Gobernador).

### Ejemplo de Solicitud
```bash
curl -X GET "http://localhost:8000/api/v1/ballot-template?polling_station_code=030390&electoral_level_id=1" \
     -H "Authorization: Bearer {tu_token_sanctum}" \
     -H "Accept: application/json"
```

### Respuesta `200 OK`
```json
{
  "data": {
    "station": {
      "id": 1,
      "code": "030390",
      "registered_voters": 300,
      "status": "ACTIVE",
      "department_name": "LIMA",
      "province_name": "LIMA",
      "district_name": "LIMA"
    },
    "electoral_level": {
      "id": 1,
      "code": "REGIONAL_GOBERNADOR",
      "name": "Gobernador y Vicegobernador Regional",
      "has_preferential_vote": false
    },
    "lists": [
      {
        "electoral_list_id": 4,
        "political_organization_id": 4,
        "political_organization_name": "ACCIÓN POPULAR",
        "political_organization_short_name": "AP",
        "logo_url": "https://.../4.png",
        "local_logo_url": "4.webp",
        "candidates": [
          {
            "candidate_id": 101,
            "candidate_name": "JUAN PEREZ",
            "position": "GOBERNADOR REGIONAL",
            "list_number": 1
          }
        ]
      }
    ]
  }
}
```
