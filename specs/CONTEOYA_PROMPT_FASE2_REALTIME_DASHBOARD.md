# Prompt — ConteoYA Fase 2: Consolidación, Dashboard y tiempo real

Actúa como **Software Architect + Backend Architect + Frontend Architect + Realtime Systems Engineer + Data/Performance Engineer**.

El proyecto es **ConteoYA**.

La Fase 1 ya permite capturar y sincronizar actas.

Ahora debemos construir la plataforma de visualización.

## Stack

### Backend

- Laravel 13
- PHP 8.5
- PostgreSQL
- Redis
- Laravel Reverb
- Laravel Sanctum

### Web

- Vue 3.5
- TypeScript 5.9
- Vuetify 4
- Tailwind CSS
- Vite 8
- Pinia
- Laravel Echo
- pusher-js

### Mobile

- Flutter 3.44
- SQLite + Drift
- misma API

---

# 1. Objetivo

Mostrar resultados consolidados:

```text
Regional
 └── Gobernador/Vicegobernador
 └── Consejo Regional

Provincial
 └── Alcalde Provincial
 └── Regidores

Distrital
 └── Alcalde Distrital
 └── Regidores
```

Por:

- región;
- provincia;
- distrito;
- mesa;
- organización política;
- candidato/lista;
- avance de actas.

---

# 2. Consolidación

No calcular estadísticas pesadas directamente en cada request.

Diseñar:

```text
acts
  ↓
confirmed acts
  ↓
aggregation
  ↓
read models / summary tables / cache
  ↓
dashboard
```

Redis puede utilizarse para datos calientes.

PostgreSQL permanece como fuente de verdad.

---

# 3. Métricas

Mostrar:

```text
Mesas esperadas
Mesas recibidas
Mesas pendientes
% cobertura
Actas confirmadas
Actas observadas
Actas con inconsistencias
Electores hábiles
Ciudadanos que votaron
Participación
Votos válidos
Blancos
Nulos
Impugnados
```

---

# 4. Resultados

Por organización:

```text
Organización
Votos
%
Ranking
```

Por candidatura:

```text
Candidato
Organización
Votos
%
Ranking
```

Nunca confundir:

```text
% votos válidos
```

con:

```text
% votos emitidos
```

Mostrar ambos cuando corresponda.

---

# 5. Realtime

Arquitectura:

```text
Acta confirmada
       │
       ▼
Domain Event
       │
       ▼
Queue
       │
       ▼
Aggregation
       │
       ▼
Broadcast Event
       │
       ▼
Laravel Reverb
       │
       ▼
Laravel Echo
       │
   ┌───┴────┐
   ▼        ▼
 Vue      Flutter
```

Eventos:

```text
ActConfirmed
ActUpdated
CoverageUpdated
ResultUpdated
```

---

# 6. Laravel Reverb

Usar:

```text
Laravel Reverb
Laravel Echo
pusher-js
```

No introducir Socket.IO salvo que exista una necesidad concreta que Reverb no cubra.

Definir canales privados y autorización.

Ejemplo conceptual:

```text
private-election.{electionId}
private-region.{regionId}
private-province.{provinceId}
private-district.{districtId}
```

Controlar qué usuarios pueden escuchar cada canal.

---

# 7. Vue

Crear módulos:

```text
dashboard
results
coverage
maps
acts
organizations
candidates
reports
```

Pinia:

```text
authStore
electionStore
dashboardStore
resultsStore
realtimeStore
```

---

# 8. Dashboard

Diseñar inicialmente:

### General

```text
Total mesas
Recibidas
Pendientes
Cobertura
Participación
```

### Ranking

```text
1. Organización A
2. Organización B
3. Organización C
```

### Mapa

Mostrar avance territorial.

### Tendencia

Actas recibidas por hora.

---

# 9. App Flutter

Agregar modo dashboard.

Debe mostrar:

- avance;
- resultados;
- cobertura;
- alertas;
- últimas actas recibidas.

No debe descargar constantemente toda la BD.

Usar endpoints agregados y actualizaciones realtime.

---

# 10. Performance

Evitar:

```text
N+1
```

Usar:

- índices;
- agregaciones optimizadas;
- Redis;
- pagination;
- read models;
- consultas específicas;
- caching;
- queues.

Preparar pruebas para alta concurrencia.

---

# 11. Reportes

Crear:

```text
Regional
Provincial
Distrital
Mesa
Organización política
Candidato
Cobertura
Participación
```

Permitir exportación cuando corresponda.

---

# 12. Criterio de aceptación

Cuando una nueva acta sea confirmada:

```text
Personero
   ↓
API
   ↓
PostgreSQL
   ↓
consolidación
   ↓
evento
   ↓
Reverb
   ↓
Vue + Flutter
```

Los usuarios autorizados deben visualizar el cambio sin refrescar manualmente.

El sistema debe continuar funcionando aunque temporalmente el canal realtime no esté disponible; el cliente debe poder recuperar el estado mediante API.
