---
name: flutter-rules
description: Conventions for the Flutter app under lib/** and any tests
  under test/**. Covers state management (control + flutter_bloc), routing
  (elixir), networking (thunder), database (drift), and the hand-written
  state-equality pattern. Loaded when Claude touches files in those paths.
globs:
  - "lib/**"
  - "test/**"
---

# Flutter rules (lib/**, test/**)

## Feature layout

Each feature under `lib/src/features/<feature>/` follows this structure;
do not invent new top-level dirs without a reason:

```
controller/<name>/<name>_controller.dart + <name>_state.dart   # control package
bloc/<name>_cubit.dart | <name>_bloc.dart                       # flutter_bloc
data/<feature>_repository.dart                                  # in-app cache/wrapper
model/...
screen/<screen>.dart
state/<screen>_state.dart
service/...
widget/...
```

The state file is always a `part of` the controller file. Pattern:

```dart
// course_controller.dart
part 'course_state.dart';
```

## State management: `control` package

The dominant pattern. Real example from `lib/src/features/course/controller/course/`:

```dart
final class CourseController extends StateController<CourseState>
    with SequentialControllerHandler {
  CourseController({
    required final ICourseRepository repository,
    required final Connectivity connectivity,
  }) : _repository = repository,
       _connectivity = connectivity,
       super(initialState: const CourseState());

  final ICourseRepository _repository;
  final Connectivity _connectivity;

  void getAllOnlineCourse() => handle(
    () async {
      setState(state.copyWith(status: StateStatus.loading));
      final result = await _repository.getAllOnlineCourses(page: const Pagination(1));
      setState(state.copyWith(status: StateStatus.success, allOnlineCourses: result));
    },
    error: (error, stackTrace) async {
      l.s('CourseController > getAllOnlineCourse: $error', stackTrace);
      setState(state.copyWith(status: StateStatus.error, error: error.toString()));
    },
    done: () async => setState(state.copyWith(status: StateStatus.idle)),
  );
}
```

Rules drawn from this pattern, all enforced by code review:

- Public methods return `void` and immediately call `handle(() async { ... },
  error: ..., done: ...)`. Do not `await` from a synchronous public method.
- The `error:` callback logs via `l.s('<Controller> > <method>: $error',
  stackTrace)` and sets `status: StateStatus.error, error: error.toString()`.
- The `done:` callback resets `status: StateStatus.idle`. (Not `.success`
  — success is set inside the body before `done` runs.)
- Use `SequentialControllerHandler` mixin when the controller can be
  re-entered before its previous call finishes; use `DroppableControllerHandler`
  when re-entries should be ignored. Mirrors the `sequential_cubit` /
  `droppable_cubit` pair under `lib/src/common/util/`.
- Inject dependencies as `final` private fields. Required-named params
  come first; the `always_put_required_named_parameters_first` lint enforces
  this.

## State management: `flutter_bloc` (Cubit/Bloc)

Some features use `flutter_bloc` instead. When you do:

- Extend `Cubit<T>` for simple state transitions. For event-driven flows,
  extend `Bloc<Event, State>` with the `event` class hand-written (this
  project does not use `freezed` for events).
- Use the `SequentialCubit` mixin or `DroppableCubit` from
  `lib/src/common/util/` to match the `control` package's concurrency
  semantics. Do not invent a new concurrency strategy.

## State classes (hand-written equality)

The project does **not** use `freezed` or `equatable`. State classes are
hand-written `final class`es with manual `copyWith`, `==`, `hashCode`, and
`toString`. Real example from `course_state.dart`:

```dart
part of 'course_controller.dart';

@immutable
final class CourseState {
  const CourseState({
    this.status = StateStatus.idle,
    this.userEnrolledOnlineCourses = const [],
    this.error,
  });

  final StateStatus status;
  final List<OnlineCourseModel> userEnrolledOnlineCourses;
  final String? error;

  CourseState copyWith({
    StateStatus? status,
    List<OnlineCourseModel>? userEnrolledOnlineCourses,
    String? error,
  }) => CourseState(
    status: status ?? this.status,
    userEnrolledOnlineCourses: userEnrolledOnlineCourses ?? this.userEnrolledOnlineCourses,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseState &&
        other.status == status &&
        listEquals(other.userEnrolledOnlineCourses, userEnrolledOnlineCourses) &&
        other.error == error;
  }

  @override
  int get hashCode =>
      status.hashCode ^ userEnrolledOnlineCourses.hashCode ^ error.hashCode;

  @override
  String toString() => '''CourseState(status: $status, error: $error)''';
}
```

Rules:

- Use `listEquals` / `mapEquals` / `setEquals` from
  `package:flutter/foundation.dart` for collection fields in `==`. A raw
  `==` on `List`/`Map` checks identity and breaks rebuild diffing.
- Do not introduce `freezed` or `equatable` to a feature that uses the
  hand-written pattern. Match the surrounding style.
- `StateStatus` (from `lib/src/common/util/state_status.dart`) is the
  canonical status enum: `idle`, `loading`, `loadingMore`, `success`,
  `noInternetConnection`, `error`. Use its `.maybeMap` / `.map` helpers
  in widgets rather than chained `if (state.status == ...)`.

## Routing: `elixir`

- Routes are defined per-feature in `lib/src/common/router/`. Add a new
  page file beside the existing ones; do not register routes inline at
  the call site.
- Do not call `Navigator.of(context).push(...)` directly when an `elixir`
  page exists for the destination; route through the existing definition
  so deep links continue to work.

## Networking: `thunder` + `ws`

- HTTP goes through `ApiService` in `data/lib/src/common/...`. Inside
  feature repositories under `data/`, call `apiService.request<T>(url,
  method: ..., data: ..., queryParams: ...)`. Do not construct new
  `Thunder` clients in feature code.
- WebSocket connections use the `ws` package; see
  `lib/src/features/authentication/data/registration_mentor_ws_repository.dart`
  for the project's idiom.

## Database: `drift`

- Schema is at `lib/src/common/database/app_database.dart`. Adding a table
  requires bumping `schemaVersion` and writing a migration in the same
  edit.
- Run `make build_runner` (or `make gen`) after any drift change so the
  generated `*.g.dart` and `*.drift.dart` files refresh.

## Widgets

- Keep widget files under ~250 lines. Extract subwidgets into the
  feature's `widget/` directory; do not extend.
- For long screens, prefer `Sliver*` composition (the project already does
  this — see `course/screen/sliver_sticky_header_widget.dart`).
- Theme tokens and shared widgets live in `packages/ui/`. Reach for them
  before recreating styles inline.

## Logging in controllers

Every `error:` callback in `handle(...)` must call `l.s(...)`. The message
prefix is `'<ControllerName> > <method>: $error'`. Stack trace is the
second arg. This is what makes the production crashlytics view readable.

## Tests

- The top-level `test/` directory currently holds only JSON fixtures —
  there is no convention for Dart unit tests yet. When you add the first
  one for a feature, mirror the production path
  (`test/features/<feature>/...`) and use plain `package:flutter_test`.
  Do **not** introduce `mocktail`, `mockito`, or `bloc_test` without
  discussing it first; the test conventions need to be decided once and
  applied consistently.
