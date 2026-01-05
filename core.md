# Dynamic Form Builder Flutter Package (Code-Only, MVVM + Riverpod)

This document contains a full **code-first dynamic form builder** design and implementation plan, now enhanced with **validation and theming support**.

---

## 6. Validation Engine (Sync + Async)

### FieldValidator Typedef

```dart
import '../core/form_context.dart';
import '../core/form_state.dart';

typedef FieldValidator = Future<String?> Function(FormContext ctx, String fieldId, dynamic value);
```

### Validator Registry

```dart
class ValidatorRegistry {
  final Map<String, List<FieldValidator>> _validators = {};

  void register(String fieldId, FieldValidator validator) {
    _validators.putIfAbsent(fieldId, () => []).add(validator);
  }

  Future<void> validate(FormContext ctx) async {
    final newErrors = <String, String?>{};
    for (final entry in _validators.entries) {
      final value = ctx.value(entry.key);
      for (final validator in entry.value) {
        final error = await validator(ctx, entry.key, value);
        if (error != null) newErrors[entry.key] = error;
      }
    }
    ctx.setAllErrors(newErrors);
  }
}
```

### Extending FormContext to set all errors

```dart
extension FormContextExtensions on FormContext {
  void setAllErrors(Map<String, String?> errors) {
    errors.forEach((key, value) => setFieldError(key, value));
  }
}
```

### Example Validator

```dart
Future<String?> requiredValidator(FormContext ctx, String fieldId, dynamic value) async {
  if (value == null || value.toString().isEmpty) return 'This field is required';
  return null;
}
```

---

## 7. Theming Support

### FormTheme

```dart
import 'package:flutter/material.dart';

class FormTheme {
  final TextStyle labelStyle;
  final TextStyle errorStyle;
  final Color fieldBorderColor;
  final Color disabledColor;

  const FormTheme({
    required this.labelStyle,
    required this.errorStyle,
    required this.fieldBorderColor,
    required this.disabledColor,
  });

  factory FormTheme.defaultTheme() => const FormTheme(
        labelStyle: TextStyle(fontSize: 16, color: Colors.black),
        errorStyle: TextStyle(fontSize: 12, color: Colors.red),
        fieldBorderColor: Colors.grey,
        disabledColor: Colors.grey,
      );
}
```

### Theme Injection

```dart
class FormThemeProvider extends InheritedWidget {
  final FormTheme theme;

  const FormThemeProvider({super.key, required this.theme, required super.child});

  static FormTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FormThemeProvider>();
    return provider?.theme ?? FormTheme.defaultTheme();
  }

  @override
  bool updateShouldNotify(covariant FormThemeProvider oldWidget) => theme != oldWidget.theme;
}
```

### Usage in FormTextField

```dart
final theme = FormThemeProvider.of(context);
return TextField(
  enabled: !state.disabledFields.contains(fieldId),
  decoration: InputDecoration(
    labelText: label,
    labelStyle: theme.labelStyle,
    errorText: state.errors[fieldId],
    errorStyle: theme.errorStyle,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.fieldBorderColor),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: theme.disabledColor),
    ),
  ),
  onChanged: (v) => vm.setValue(fieldId, v),
);
```

---

This completes the **next layer** of the package with **validation and theming support**, fully integrated into the MVVM + Riverpod structure.

Next steps could include **multi-step/wizard forms** and **dynamic async field loading** for enterprise scenarios.
