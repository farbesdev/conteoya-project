---
name: flutter-dart-best-practices
description: >
  Experto y buenas prácticas en Flutter 3.44+ y Dart para aplicaciones móviles
  de misión crítica. Cubre arquitectura de features, state management, navegación,
  testing, rendimiento y patrones específicos para apps electorales offline-first.
  Activar en "flutter", "dart", "widget", "provider", "riverpod", "bloc", "mobile".
---

# Experto y Buenas Prácticas en Flutter 3.44+ y Dart

## 1. Arquitectura de la Aplicación

### Estructura de carpetas recomendada (Feature-First)
```
lib/
├── core/
│   ├── constants/          # AppColors, AppStrings, AppRoutes
│   ├── errors/             # Failures, Exceptions tipadas
│   ├── network/            # NetworkInfo, ConnectivityChecker
│   ├── services/           # AudioService, NotificationService
│   └── utils/              # DateFormatter, SHA256Helper, FileSizeValidator
├── features/
│   ├── auth/
│   │   ├── data/           # AuthRemoteDataSource, AuthLocalDataSource, AuthRepositoryImpl
│   │   ├── domain/         # AuthRepository (interfaz), LoginUseCase, AuthEntity
│   │   └── presentation/   # LoginPage, LoginBloc/Notifier, LoginState
│   ├── acts/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── sync/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/            # Widgets reutilizables
│   └── extensions/         # Extension methods Dart
└── main.dart
```

### Patrón de capas (Clean Architecture)
- **Domain:** Solo Dart puro. Sin dependencias de Flutter, Drift, Dio, etc.
- **Data:** Implementa contratos del dominio. Accede a APIs, BD local, filesystem.
- **Presentation:** Widgets + State Management. Sin lógica de negocio directa.

---

## 2. State Management

### Riverpod 2+ (recomendado para ConteoYA)
```dart
// Preferir AsyncNotifier sobre StateNotifier para operaciones async
@riverpod
class ActFormNotifier extends _$ActFormNotifier {
  @override
  ActFormState build() => ActFormState.initial();

  Future<void> submitAct(ActDraft draft) async {
    state = state.copyWith(status: FormStatus.loading);
    final result = await ref.read(createActUseCaseProvider).call(draft);
    result.fold(
      (failure) => state = state.copyWith(status: FormStatus.error, failure: failure),
      (act)     => state = state.copyWith(status: FormStatus.success, act: act),
    );
  }
}
```

### Reglas de state management
- **NUNCA** usar `setState` para estado global o compartido entre pantallas.
- **SIEMPRE** modelar estados como clases selladas (`sealed class` Dart 3+).
- Separar el estado de UI del estado de dominio.

```dart
// ✅ Estado tipado y exhaustivo
sealed class SyncStatus {
  const SyncStatus();
}
class SyncIdle     extends SyncStatus { const SyncIdle(); }
class SyncLoading  extends SyncStatus { const SyncLoading(); }
class SyncSuccess  extends SyncStatus { const SyncSuccess(this.count); final int count; }
class SyncFailure  extends SyncStatus { const SyncFailure(this.message); final String message; }
```

---

## 3. Dart — Principios Críticos

### Tipado estricto
```dart
// ❌ Nunca usar dynamic
dynamic result = fetchAct();

// ✅ Siempre tipar
Either<Failure, Act> result = await fetchAct();
```

### Null Safety
- Activar `sound null safety` siempre (`dart analyze --fatal-infos`).
- Usar `required` en constructores en lugar de parámetros opcionales sin default.
- Evitar el operador `!` (bang operator) — en su lugar usar `?.`, `??`, `if (x != null)`.

### Immutability
```dart
// ✅ Usar freezed para modelos inmutables
@freezed
class ActDraft with _$ActDraft {
  const factory ActDraft({
    required String pollingStationCode,
    required int    registeredVoters,
    required List<VoteResult> results,
    @Default([]) List<String> warnings,
  }) = _ActDraft;

  factory ActDraft.fromJson(Map<String, dynamic> json) => _$ActDraftFromJson(json);
}
```

### Functional error handling (dartz / fpdart)
```dart
// ✅ Either<Failure, T> para operaciones que pueden fallar
Future<Either<Failure, Act>> createAct(ActDraft draft);

// ✅ Fold para manejar ambos casos
result.fold(
  (failure) => showErrorSnackbar(failure.message),
  (act)     => navigateToActSummary(act),
);
```

---

## 4. Networking (Dio)

### Configuración base
```dart
// dio_client.dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl:         AppConfig.apiBaseUrl,
    connectTimeout:  const Duration(seconds: 10),
    receiveTimeout:  const Duration(seconds: 30),
    sendTimeout:     const Duration(seconds: 60), // uploads pesados
  ));
  dio.interceptors.addAll([
    AuthInterceptor(ref),       // Inyecta Bearer token
    LoggingInterceptor(),       // Solo en DEBUG
    RetryInterceptor(dio: dio), // Reintentos automáticos
  ]);
  return dio;
});
```

### Reglas de red
- **SIEMPRE** manejar `DioException` y mapearla a un `Failure` del dominio.
- **NUNCA** hacer requests directamente desde widgets.
- Usar `CancelToken` para cancelar requests al salir de la pantalla.
- Implementar `ConnectivityChecker` antes de intentar sincronización.

---

## 5. Imágenes y Cámara

### Captura de fotografía de acta
```dart
// Orden de pasos obligatorio:
// 1. Capturar con image_picker / camera
// 2. Validar MIME (solo image/jpeg, image/png)
// 3. Validar tamaño (máx 10MB)
// 4. Generar SHA-256 del archivo
// 5. Guardar copia local en getApplicationDocumentsDirectory()
// 6. Registrar en BD local (Drift) con hash, size, mime, path, captured_at
// 7. Encolar en SyncOperation para subida posterior a R2

Future<Either<Failure, EvidenceLocal>> captureEvidence(ActLocalId actId) async {
  final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
  if (file == null) return left(const UserCancelledFailure());

  final bytes     = await file.readAsBytes();
  final mimeType  = lookupMimeType(file.path) ?? 'image/jpeg';
  final sha256    = _computeSha256(bytes);
  final savedPath = await _saveLocally(bytes, sha256);

  return right(EvidenceLocal(sha256: sha256, localPath: savedPath, mimeType: mimeType, ...));
}
```

---

## 6. Rendimiento

- Usar `const` constructors en todos los widgets que no dependan de parámetros dinámicos.
- Usar `RepaintBoundary` alrededor de widgets animados pesados.
- Preferir `ListView.builder` / `SliverList` sobre `Column` con `.map()` en listas largas.
- Cargar imágenes con `CachedNetworkImage` y cache local.
- Usar `compute()` para procesamiento pesado en isolate separado (hash SHA-256, parsing JSON grande).

---

## 7. Testing

```dart
// Unit test — UseCase
test('createAct saves draft to local database', () async {
  final mockRepo = MockActRepository();
  when(mockRepo.save(any)).thenAnswer((_) async => right(tAct));
  final useCase = CreateActUseCase(mockRepo);
  final result  = await useCase(tDraft);
  expect(result, right(tAct));
});

// Widget test — formulario de acta
testWidgets('ActForm shows validation warning when totals mismatch', (tester) async {
  await tester.pumpWidget(ProviderScope(child: ActFormPage()));
  await tester.enterText(find.byKey(const Key('blank_votes_field')), '999');
  await tester.tap(find.byKey(const Key('validate_button')));
  await tester.pump();
  expect(find.text('Los totales no coinciden'), findsOneWidget);
});
```

---

## 8. Reglas Críticas para ConteoYA

| Regla | Descripción |
|-------|-------------|
| **La IA nunca confirma** | OCR/IA solo propone. El personero confirma siempre. |
| **Offline es el modo normal** | Toda operación funciona sin internet. La sync es asíncrona. |
| **No usar dynamic** | Todo el código debe ser type-safe. |
| **SHA-256 en cliente** | Computar hash antes de guardar y antes de subir. |
| **client_operation_id** | Toda sync operation incluye UUID idempotente. |
| **Ownership de mesa** | Verificar localmente (y luego en el backend) que el personero tiene asignada esa mesa. |
