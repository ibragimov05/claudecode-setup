# Dart Model Generation Skill

Generate a Dart model class for this project from a JSON shape or description.
Follow every rule below exactly — the output must be indistinguishable from
hand-written code in this repo.

---

## Quick checklist

- [ ] `@immutable final class` (or plain `class` only if the file already uses that)
- [ ] `const` constructor, required fields first, optional last (no positional params)
- [ ] `factory fromJson(Map<String, Object?> json)` — **never** use `!`
- [ ] Fields declared **after** `fromJson`
- [ ] `toJson()` → `Map<String, Object?>` (only when the model is sent to the server)
- [ ] `copyWith` with `ValueGetter<T>?` pattern
- [ ] Manual `==` (with `identical` guard + `listEquals`/`mapEquals` for collections)
- [ ] `hashCode` via XOR chain or `Object.hash()`
- [ ] `toString` single-line triple-quoted string
- [ ] Companion enums (if any) go in the **same file**, above or below the class

---

## File & class naming

| Thing | Convention |
|---|---|
| File | `snake_case_model.dart` |
| Class | `PascalCaseModel` — use `final class` for leaf types |
| Enum | `PascalCaseEnum` in the same file |

---

## Class skeleton

```dart
import 'package:flutter/foundation.dart'; // for @immutable, ValueGetter, listEquals, mapEquals

@immutable
final class ExampleModel {
  const ExampleModel({
    required this.id,
    required this.name,
    this.description,        // optional / nullable fields come last
  });

  factory ExampleModel.fromJson(Map<String, Object?> json) => ExampleModel(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
  );

  final int id;
  final String name;
  final String? description;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  ExampleModel copyWith({
    ValueGetter<int>? id,
    ValueGetter<String>? name,
    ValueGetter<String?>? description,
  }) => ExampleModel(
    id: id != null ? id() : this.id,
    name: name != null ? name() : this.name,
    description: description != null ? description() : this.description,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExampleModel &&
        other.id == id &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ description.hashCode;

  @override
  String toString() =>
      'ExampleModel(id: $id, name: $name, description: $description)';
}
```

---

## fromJson parsing rules (MANDATORY)

**Never use `!` (bang operator).** Always use null-aware chaining + `tryParse` + `??`.

| Field type | Pattern |
|---|---|
| `int` | `int.tryParse(json['key']?.toString() ?? '') ?? 0` |
| `int?` | `int.tryParse(json['key']?.toString() ?? '')` |
| `double` | `double.tryParse(json['key']?.toString() ?? '') ?? 0.0` |
| `bool` | `bool.tryParse(json['key']?.toString() ?? '') ?? false` |
| `String` (required) | `json['key']?.toString() ?? ''` |
| `String?` | `json['key']?.toString()` |
| `DateTime?` | `DateTime.tryParse(json['key']?.toString() ?? '')?.toLocal()` |
| `DateTime` (required) | `DateTime.tryParse(json['key']?.toString() ?? '') ?? DateTime.now()` |
| `List<T>` | See list pattern below |
| Nested object | See nested pattern below |
| Localized map `Map<String, String>` | See map pattern below |
| Enum | Define a `fromValue` static on the enum; call it from `fromJson` |

### List pattern

```dart
items: switch (json['items']) {
  final List<Object?> list =>
    list.whereType<Map<String, Object?>>().map(ItemModel.fromJson).toList(),
  _ => <ItemModel>[],
},
```

### Nullable nested object pattern

```dart
address: switch (json['address']) {
  final Map<String, Object?> map => AddressModel.fromJson(map),
  _ => null,
},
```

### Localized map pattern (`Map<String, String>`)

```dart
title: switch (json['title']) {
  Map<String, Object?> title => title.map((k, v) => MapEntry(k, v.toString())),
  _ => {},
},
```

---

## copyWith — always use `ValueGetter<T>?`

This allows setting nullable fields to `null` explicitly:

```dart
// Nullable field example — ValueGetter<String?> lets callers pass () => null
ValueGetter<String?>? description,
// ...
description: description != null ? description() : this.description,
```

Do **not** use the plain `T? field` pattern (it cannot clear nullable fields).

---

## Equality

- Always start with `if (identical(this, other)) return true;`
- Use `listEquals(other.items, items)` for `List` fields
- Use `mapEquals(other.map, map)` for `Map` fields
- Import from `package:flutter/foundation.dart`

---

## hashCode

Prefer XOR chain for clarity; use `Object.hash(...)` / `Object.hashAll(...)` for
many fields (>8) or when mixing collection hashes:

```dart
// XOR (preferred for ≤ ~8 fields)
@override
int get hashCode => id.hashCode ^ name.hashCode ^ description.hashCode;

// Object.hash (preferred for many fields or collection fields)
@override
int get hashCode => Object.hash(id, name, description, Object.hashAll(items));
```

---

## toString

Use a triple-quoted single-line string so it reads naturally in logs:

```dart
@override
String toString() =>
    '''ExampleModel(id: $id, name: $name, description: $description)''';
```

---

## Enums (companion)

Put enums in the same file. Provide a `fromValue` factory and `isX` bool getters:

```dart
enum StatusEnum {
  active('active'),
  inactive('inactive');

  const StatusEnum(this.value);

  static StatusEnum fromValue(String? value) => switch (value?.toLowerCase()) {
    'active' => active,
    'inactive' => inactive,
    _ => inactive,  // safe default
  };

  final String value;

  bool get isActive => this == active;
  bool get isInactive => this == inactive;
}
```

Use it in `fromJson`:

```dart
status: StatusEnum.fromValue(json['status']?.toString()),
```

---

## Imports

Always add only what the file actually needs:

```dart
import 'package:flutter/foundation.dart'; // @immutable, ValueGetter, listEquals, mapEquals
```

Add `package:collection/collection.dart` only when using `DeepCollectionEquality`
or `firstWhereOrNull` — prefer `listEquals` from `flutter/foundation.dart` for
simple list equality.

---

## What NOT to do

- No `freezed` or `json_serializable` — all models are hand-written
- No `dynamic` — always `Object?` in JSON maps
- No bang operator `!` anywhere in parsing
- No `Map<String, dynamic>` — always `Map<String, Object?>`
- No code-generation annotations (`@JsonSerializable`, `@freezed`, etc.)
- No positional constructor parameters
- No Equatable or any base equality mixin
- No `print` or `debugPrint` — logging belongs in controllers, not models

---

## Full example with all field types

```dart
import 'package:flutter/foundation.dart';

enum OrderStatus {
  pending('pending'),
  completed('completed'),
  cancelled('cancelled');

  const OrderStatus(this.value);

  static OrderStatus fromValue(String? value) => switch (value?.toLowerCase()) {
    'completed' => completed,
    'cancelled' => cancelled,
    _ => pending,
  };

  final String value;

  bool get isPending => this == pending;
  bool get isCompleted => this == completed;
  bool get isCancelled => this == cancelled;
}

@immutable
final class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.isActive,
    required this.createdAt,
    this.note,
    this.completedAt,
  });

  factory OrderModel.fromJson(Map<String, Object?> json) => OrderModel(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    userId: json['user_id']?.toString() ?? '',
    status: OrderStatus.fromValue(json['status']?.toString()),
    totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0.0,
    items: switch (json['items']) {
      final List<Object?> list =>
        list.whereType<Map<String, Object?>>().map(OrderItemModel.fromJson).toList(),
      _ => <OrderItemModel>[],
    },
    isActive: bool.tryParse(json['is_active']?.toString() ?? '') ?? false,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
    note: json['note']?.toString(),
    completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? '')?.toLocal(),
  );

  final int id;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final List<OrderItemModel> items;
  final bool isActive;
  final DateTime? createdAt;
  final String? note;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'user_id': userId,
    'status': status.value,
    'total_amount': totalAmount,
    'items': items.map((e) => e.toJson()).toList(),
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'note': note,
    'completed_at': completedAt?.toIso8601String(),
  };

  OrderModel copyWith({
    ValueGetter<int>? id,
    ValueGetter<String>? userId,
    ValueGetter<OrderStatus>? status,
    ValueGetter<double>? totalAmount,
    ValueGetter<List<OrderItemModel>>? items,
    ValueGetter<bool>? isActive,
    ValueGetter<DateTime?>? createdAt,
    ValueGetter<String?>? note,
    ValueGetter<DateTime?>? completedAt,
  }) => OrderModel(
    id: id != null ? id() : this.id,
    userId: userId != null ? userId() : this.userId,
    status: status != null ? status() : this.status,
    totalAmount: totalAmount != null ? totalAmount() : this.totalAmount,
    items: items != null ? items() : this.items,
    isActive: isActive != null ? isActive() : this.isActive,
    createdAt: createdAt != null ? createdAt() : this.createdAt,
    note: note != null ? note() : this.note,
    completedAt: completedAt != null ? completedAt() : this.completedAt,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderModel &&
        other.id == id &&
        other.userId == userId &&
        other.status == status &&
        other.totalAmount == totalAmount &&
        listEquals(other.items, items) &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.note == note &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      status.hashCode ^
      totalAmount.hashCode ^
      items.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      note.hashCode ^
      completedAt.hashCode;

  @override
  String toString() =>
      '''OrderModel(id: $id, userId: $userId, status: $status, totalAmount: $totalAmount, items: $items, isActive: $isActive, createdAt: $createdAt, note: $note, completedAt: $completedAt)''';
}
```
