# FieldGuard - Clean Architecture

This project follows **Clean Architecture** principles to ensure separation of concerns, testability, and maintainability.

## Project Structure

```
lib/
├── core/                   # Shared utilities, theme, errors
│   ├── errors/            # Failures & exceptions
│   ├── responsive/        # Responsive design system
│   ├── theme/             # App colors & theme
│   └── utils/             # Constants & utilities
│
├── data/                   # Data layer (frameworks & drivers)
│   ├── datasources/       # Remote & local data sources
│   │   ├── local/         # Cache, SharedPreferences, etc.
│   │   └── remote/        # API clients (Dio)
│   ├── models/            # Data models with JSON serialization
│   └── repositories/      # Repository implementations
│
├── domain/                 # Business logic layer (entities & use cases)
│   ├── entities/          # Core business objects
│   ├── repositories/      # Repository contracts (interfaces)
│   └── usecases/          # Application business rules
│
├── presentation/           # UI layer
│   ├── providers/         # State management (Provider/ChangeNotifier)
│   ├── screens/           # Screen widgets
│   └── widgets/           # Reusable UI components
│
└── main.dart              # App entry point
```

## Layer Responsibilities

### 🎯 Domain Layer (Business Logic)
- **Entities**: Pure Dart classes representing core business concepts (e.g., `User`)
- **Repositories**: Abstract contracts defining data operations
- **Use Cases**: Single-responsibility business rules (e.g., `SignInUseCase`)
- **Rules**:
  - No dependencies on other layers
  - No Flutter/framework imports
  - Pure business logic only

### 💾 Data Layer (Data Management)
- **Models**: Data transfer objects with JSON serialization (extend domain entities)
- **Data Sources**: 
  - **Remote**: API calls using Dio
  - **Local**: Cache using SharedPreferences/Hive
- **Repository Implementations**: Concrete implementations of domain repository contracts
- **Rules**:
  - Depends on domain layer
  - Handles data transformation (JSON ↔ Models ↔ Entities)
  - Catches exceptions and converts to `Failure` objects

### 🎨 Presentation Layer (UI)
- **Screens**: Full-page widgets organized by feature
- **Providers**: State management using `ChangeNotifier` (or Bloc/Riverpod)
- **Widgets**: Reusable UI components
- **Rules**:
  - Depends on domain layer (use cases)
  - Observes state changes
  - Displays UI based on state

### 🛠️ Core Layer (Shared)
- **Errors**: `Failure` (domain) and `Exception` (data) classes
- **Theme**: Colors, typography, app theme
- **Responsive**: Screen size utilities and responsive builders
- **Utils**: Constants, helpers, extensions

## Data Flow

```
UI (Presentation)
    ↓ calls
Use Case (Domain)
    ↓ calls
Repository Interface (Domain)
    ↑ implements
Repository Implementation (Data)
    ↓ calls
Data Source (Data)
    ↓ fetches
API / Cache
```

## Error Handling

- **Exceptions** (`data/`): Thrown by data sources (e.g., `ServerException`)
- **Failures** (`domain/`): Returned by repositories using `Either<Failure, T>` from `dartz`
- **UI**: Providers handle failures and update UI state accordingly

## Key Principles

1. **Dependency Rule**: Dependencies point inward (Presentation → Domain ← Data)
2. **Separation of Concerns**: Each layer has a single, well-defined responsibility
3. **Testability**: Business logic is independent of frameworks and UI
4. **Scalability**: Easy to add new features without affecting existing code

## Example: Sign-In Flow

```dart
// 1. User taps "Sign In" button
LoginScreen → LoginProvider.signIn()

// 2. Provider calls use case
LoginProvider → SignInUseCase.call(email, password)

// 3. Use case calls repository
SignInUseCase → AuthRepository.signIn(email, password)

// 4. Repository calls remote data source
AuthRepositoryImpl → AuthRemoteDataSource.signIn(email, password)

// 5. Data source makes API call
AuthRemoteDataSourceImpl → Dio.post('/auth/sign-in')

// 6. Response flows back up
API → DataSource → Repository → UseCase → Provider → UI
```

## Adding New Features

### 1. Define Entity (Domain)
```dart
// lib/domain/entities/field_visit.dart
class FieldVisit {
  final String id;
  final DateTime timestamp;
  // ...
}
```

### 2. Create Repository Contract (Domain)
```dart
// lib/domain/repositories/field_visit_repository.dart
abstract class FieldVisitRepository {
  Future<Either<Failure, List<FieldVisit>>> getVisits();
}
```

### 3. Create Use Case (Domain)
```dart
// lib/domain/usecases/get_visits_usecase.dart
class GetVisitsUseCase {
  final FieldVisitRepository _repository;
  Future<Either<Failure, List<FieldVisit>>> call() => _repository.getVisits();
}
```

### 4. Create Model (Data)
```dart
// lib/data/models/field_visit_model.dart
class FieldVisitModel extends FieldVisit {
  factory FieldVisitModel.fromJson(Map<String, dynamic> json) { ... }
}
```

### 5. Implement Data Source (Data)
```dart
// lib/data/datasources/remote/field_visit_remote_datasource.dart
class FieldVisitRemoteDataSourceImpl {
  Future<List<FieldVisitModel>> getVisits() async { ... }
}
```

### 6. Implement Repository (Data)
```dart
// lib/data/repositories/field_visit_repository_impl.dart
class FieldVisitRepositoryImpl implements FieldVisitRepository {
  // Coordinates remote & local data sources
}
```

### 7. Create Provider (Presentation)
```dart
// lib/presentation/providers/field_visit_provider.dart
class FieldVisitProvider extends ChangeNotifier {
  final GetVisitsUseCase _getVisits;
  // State management logic
}
```

### 8. Build UI (Presentation)
```dart
// lib/presentation/screens/field_visits/field_visits_screen.dart
class FieldVisitsScreen extends StatelessWidget {
  // UI that observes FieldVisitProvider
}
```

## Testing Strategy

- **Unit Tests**: Domain layer (entities, use cases)
- **Integration Tests**: Data layer (repositories, data sources)
- **Widget Tests**: Presentation layer (screens, widgets)
- **E2E Tests**: Full user flows

## Dependencies

- **State Management**: `provider`
- **Functional Programming**: `dartz` (Either, Option)
- **HTTP Client**: `dio`
- **Location**: `geolocator`
- **Permissions**: `permission_handler`

## Resources

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)
