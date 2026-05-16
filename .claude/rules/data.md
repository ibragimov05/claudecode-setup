---
name: data-rules
description: Conventions for the data/ package — repositories, API services,
  models, and shared utilities. Loaded when Claude touches anything under
  data/**.
globs:
  - "data/**"
---

# Data package rules (data/**)

## Repository pattern

Repositories are split into an `abstract interface class IXRepository`
plus a concrete `class XRepositoryImpl implements IXRepository`. Real
example from `data/lib/src/features/course/repositories/course_repository.dart`:

```dart
abstract interface class ICourseRepository {
  Future<PaginationModel<OnlineCourseModel>> getOnlineCoursesMy({required final Pagination page});
  Future<List<OnlineCourseModel>> getAllOnlineCourses({required final Pagination page});
  Future<void> setCurrentCourse({required final int courseId});
}

class CourseRepositoryImpl implements ICourseRepository {
  CourseRepositoryImpl({required this.apiService});

  final ApiService apiService;

  @override
  Future<PaginationModel<OnlineCourseModel>> getOnlineCoursesMy({required final Pagination page}) async {
    final response = await apiService.request<DioResponse>(
      Urls.onlineCoursesMy,
      queryParams: {'offset': page.offset, 'limit': page.limit},
    );
    return PaginationModel.fromJson(
      json: response,
      fromJson: OnlineCourseModel.fromJson,
      dataKey: 'online_courses',
    );
  }
}
```

Rules:

- The interface is `abstract interface class`, not `abstract class`. The
  interface lives in the same file as the implementation, above it.
- Constructor params are `{required this.apiService}` style. Required
  named params come first per the `always_put_required_named_parameters_first`
  lint.
- All methods accept named parameters (no positional), and `required final`
  is the canonical prefix for non-default named params.
- Repository methods throw on failure. They do **not** return `Either`,
  `Result`, or anything that wraps errors. The caller — usually a
  `StateController.handle(error: ...)` — catches across the boundary.
  Do not introduce `dartz`, `fpdart`, or hand-rolled `Result` types.

## URLs

- All endpoint paths are constants in `data/lib/src/common/utils/urls.dart`.
  Add new endpoints there; do not inline path strings in repositories.

## Models

- Models in `data/lib/src/features/<feature>/models/` are hand-written
  with a `fromJson` factory and a `toJson` method. No `json_serializable`
  is wired in for these — the codegen lives only in
  `data/lib/src/common/models/` where it's already configured.
- Match the JSON key style of the existing model in the same directory
  (the backend uses `snake_case`, so `fromJson` maps explicit keys).
- Use pattern matching for tolerant decoding when the field shape varies,
  following the `getAllOnlineCourses` example:
  ```dart
  if (response case {'online_courses': final List<Object?> items}) { ... }
  throw FormatException('Invalid response body: $response');
  ```

## Pagination

- Use the `Pagination` value object from `data` for query offsets:
  `const Pagination(1)` for the first page. The repository converts that
  to `offset`/`limit` query params.
- Wrap paginated responses in `PaginationModel<T>` via its
  `PaginationModel.fromJson(json: ..., fromJson: T.fromJson, dataKey: '...')`
  factory.

## ApiService

- Inject `ApiService` into every repository. Do not instantiate
  `Thunder`, `Dio`, or any HTTP client at the repository layer — the
  configured instance lives in `data/lib/src/common/...` and threads
  middleware (auth, refresh, logging) through every call.
- The generic on `request<T>` is the response shape Thunder will hand
  you, not the model type. Most calls use `<DioResponse>` (a typedef in
  `data/lib/src/common/utils/typedefs.dart`) and decode by hand.

## Exports

- Each feature has a `data/lib/src/features/<feature>/<feature>.dart`
  barrel file that re-exports the models and the repository interface +
  impl. Add new public types there so consumers can `import 'package:data/...'`.
