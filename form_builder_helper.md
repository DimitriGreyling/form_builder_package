# Dynamic Form Builder (Flutter)

> **Architecture:** MVVM
> **State Management:** Riverpod
> **Goal:** A highly-generic, private, rock-solid form builder package that supports complex business flows, dynamic fields, hide/show logic, theming, and app-level customization without leaking concerns.

---

## 1. Core Principles (Non‑Negotiable)

1. **Strict MVVM boundaries**

   * View = Widgets only
   * ViewModel = State & intent
   * Model = Pure data
   * Domain/Service = Business flows

2. **Package never reads app providers**

3. **App injects behavior, widgets, and themes**

4. **All mutations go through the ViewModel**

5. **FormContext is the only bridge between engine and app logic**

---

## 2. High‑Level Architecture

```
APP
│
├── ProviderScope
│   ├── app providers (auth, api, etc)
│   │
│   └── DynamicForm
│       └── Internal MVVM Scope
│           ├── FormViewModel (StateNotifier)
│           ├── FormState (Model)
│           └── TransactionService (Injected)
```

---

## 3. Package Structure

```text
dynamic_form_builder/
│
├── lib/
│   ├── dynamic_form_builder.dart
│
│   ├── model/
│   │   ├── form_state.dart
│   │   ├── field_definition.dart
│   │   ├── form_error.dart
│   │
│   ├── viewmodel/
│   │   ├── form_view_model.dart
│   │   ├── form_view_model_provider.dart
│   │
│   ├── domain/
│   │   ├── form_transaction_service.dart
│   │   ├── form_context.dart
│   │
│   ├── fields/
│   │   ├── field_registry.dart
│   │
│   ├── view/
│   │   ├── dynamic_form.dart
│   │
│   └── theme/
│       ├── form_theme.dart
│       ├── dynamic_form_theme.dart
```

---

## 4. Model Layer

### `FormState`

```dart
class FormState {
  final Map<String, dynamic> values;
  final Map<String, bool> visibility;
  final Map<String, bool> enabled;

  const FormState({
    required this.values,
    required this.visibility,
    required this.enabled,
  });

  factory FormState.initial() => const FormState(
        values: {},
        visibility: {},
        enabled: {},
      );

  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, bool>? visibility,
    Map<String, bool>? enabled,
  }) {
    return FormState(
      values: values ?? this.values,
      visibility: visibility ?? this.visibility,
      enabled: enabled ?? this.enabled,
    );
  }
}
```

---

## 5. ViewModel Layer

### `FormViewModel`

```dart
class FormViewModel extends StateNotifier<FormState> {
  FormViewModel() : super(FormState.initial());

  void setValue(String fieldId, dynamic value) {
    state = state.copyWith(
      values: {...state.values, fieldId: value},
    );
  }

  void showField(String fieldId) {
    state = state.copyWith(
      visibility: {...state.visibility, fieldId: true},
    );
  }

  void hideField(String fieldId) {
    state = state.copyWith(
      visibility: {...state.visibility, fieldId: false},
    );
  }

  void enableField(String fieldId) {
    state = state.copyWith(
      enabled: {...state.enabled, fieldId: true},
    );
  }

  void disableField(String fieldId) {
    state = state.copyWith(
      enabled: {...state.enabled, fieldId: false},
    );
  }
}
```

---

## 6. Domain Layer (Business Logic)

### `FormContext`

```dart
class FormContext {
  final Ref ref;

  FormContext(this.ref);

  T? value<T>(String fieldId) =>
      ref.read(formViewModelProvider).values[fieldId] as T?;

  void setValue(String fieldId, dynamic value) =>
      ref.read(formViewModelProvider.notifier).setValue(fieldId, value);

  void show(String fieldId) =>
      ref.read(formViewModelProvider.notifier).showField(fieldId);

  void hide(String fieldId) =>
      ref.read(formViewModelProvider.notifier).hideField(fieldId);

  void enable(String fieldId) =>
      ref.read(formViewModelProvider.notifier).enableField(fieldId);

  void disable(String fieldId) =>
      ref.read(formViewModelProvider.notifier).disableField(fieldId);

  Map<String, dynamic> get allValues =>
      ref.read(formViewModelProvider).values;
}
```

### `FormTransactionService`

```dart
abstract class FormTransactionService {
  void onInit(FormContext ctx) {}

  void onFieldChanged(FormContext ctx, String fieldId, dynamic value) {}

  Future<void> onSubmit(FormContext ctx);
}
```

---

## 7. View Layer

### `FieldRegistry`

```dart
typedef FieldBuilder = Widget Function(
  BuildContext context,
  FormContext ctx,
  FieldDefinition field,
);

class FieldRegistry {
  final Map<String, FieldBuilder> builders;

  const FieldRegistry(this.builders);

  Widget build(BuildContext context, FormContext ctx, FieldDefinition field) {
    final builder = builders[field.type];
    if (builder == null) {
      throw Exception('Unknown field type: ${field.type}');
    }
    return builder(context, ctx, field);
  }
}
```

### `DynamicForm`

```dart
class DynamicForm extends ConsumerWidget {
  final List<FieldDefinition> fields;
  final FieldRegistry registry;
  final Provider<FormTransactionService> serviceProvider;

  const DynamicForm({
    required this.fields,
    required this.registry,
    required this.serviceProvider,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(formViewModelProvider);
    final service = ref.watch(serviceProvider);
    final ctx = FormContext(ref);

    return Column(
      children: [
        for (final field in fields)
          if (state.visibility[field.id] ?? true)
            registry.build(context, ctx, field),
        ElevatedButton(
          onPressed: () => service.onSubmit(ctx),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
```

---

## 8. Theming (Enhanced)

### Goals

* Package defines **theme contract only**
* App provides the actual theme
* No dependency on `Theme.of(context)` for logic

### `FormTheme`

```dart
class FormTheme {
  final InputDecorationTheme inputDecorationTheme;
  final TextStyle labelStyle;
  final Color errorColor;
  final EdgeInsets fieldSpacing;

  const FormTheme({
    required this.inputDecorationTheme,
    required this.labelStyle,
    required this.errorColor,
    required this.fieldSpacing,
  });
}
```

### `DynamicFormTheme`

```dart
class DynamicFormTheme extends InheritedWidget {
  final FormTheme theme;

  const DynamicFormTheme({
    required this.theme,
    required super.child,
    super.key,
  });

  static FormTheme of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<DynamicFormTheme>();
    assert(result != null, 'No DynamicFormTheme found');
    return result!.theme;
  }

  @override
  bool updateShouldNotify(covariant DynamicFormTheme oldWidget) {
    return oldWidget.theme != theme;
  }
}
```

### Using Theme in Field Widgets

```dart
Widget textFieldBuilder(
  BuildContext context,
  FormContext ctx,
  FieldDefinition field,
) {
  final theme = DynamicFormTheme.of(context);

  return Padding(
    padding: theme.fieldSpacing,
    child: TextField(
      decoration: InputDecoration(
        labelText: field.label,
      ).applyDefaults(theme.inputDecorationTheme),
      onChanged: (value) {
        ctx.setValue(field.id, value);
      },
    ),
  );
}
```

---

## 9. App Usage Example

```dart
DynamicFormTheme(
  theme: FormTheme(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    labelStyle: const TextStyle(fontSize: 14),
    errorColor: Colors.red,
    fieldSpacing: const EdgeInsets.symmetric(vertical: 8),
  ),
  child: DynamicForm(
    fields: const [
      FieldDefinition(id: 'category', type: 'text', label: 'Category'),
      FieldDefinition(id: 'engine', type: 'text', label: 'Engine Size'),
    ],
    registry: FieldRegistry({
      'text': textFieldBuilder,
    }),
    serviceProvider: Provider(
      (ref) => CreateEquipmentService(),
    ),
  ),
);
```

---

## 10. Why This Is Rock Solid

* MVVM strictly enforced
* Riverpod scopes are isolated
* Infinite extensibility
* No business logic in UI
* App controls complexity
* Package remains reusable & private

---

## 11. Validation Engine (Non-JSON, Code-First)

### Design Goals

* Avoid JSON parsing for complex rules
* Strong typing
* Easy access to nested data
* Supports sync & async validation

### Validator Contract

```dart
typedef FieldValidator = FutureOr<FormError?> Function(
  FormContext ctx,
  String fieldId,
  dynamic value,
);
```

### Validator Registry

```dart
class ValidatorRegistry {
  final Map<String, List<FieldValidator>> _validators = {};

  void register(String fieldId, FieldValidator validator) {
    _validators.putIfAbsent(fieldId, () => []).add(validator);
  }

  Future<List<FormError>> validate(FormContext ctx) async {
    final errors = <FormError>[];

    for (final entry in _validators.entries) {
      final value = ctx.value(entry.key);
      for (final validator in entry.value) {
        final error = await validator(ctx, entry.key, value);
        if (error != null) errors.add(error);
      }
    }
    return errors;
  }
}
```

---

## 12. Error Handling (Conformed & Predictable)

### Error Model

```dart
sealed class FormError {
  final String message;
  const FormError(this.message);
}

class FieldError extends FormError {
  final String fieldId;
  const FieldError(this.fieldId, String message) : super(message);
}

class GlobalFormError extends FormError {
  const GlobalFormError(String message) : super(message);
}
```

### ViewModel Integration

Errors live in the ViewModel state, not widgets.

```dart
class FormState {
  final List<FormError> errors;
  // other fields omitted
}
```

---

## 13. Multi-Step / Wizard Support

### Step Definition

```dart
class FormStep {
  final String id;
  final List<FieldDefinition> fields;

  const FormStep({required this.id, required this.fields});
}
```

### ViewModel Extension

```dart
class FormViewModel extends StateNotifier<FormState> {
  int currentStep = 0;

  void nextStep() => currentStep++;
  void previousStep() => currentStep--;
}
```

### View Usage

```dart
final step = steps[viewModel.currentStep];
```

---

## 14. Async & Dynamic Fields

### Use Case Examples

* Load dropdown values from API
* Dynamically add/remove fields

### Pattern

* App loads data
* Injects into TransactionService
* Service updates ViewModel

```dart
class AsyncCategoryService extends FormTransactionService {
  @override
  void onInit(FormContext ctx) async {
    ctx.disable('category');
    final categories = await loadCategories();
    ctx.enable('category');
  }
}
```

---

## 15. Avoiding JSON: Better Alternatives for Complex Logic

### Why JSON Fails for Complex Forms

* Nested path updates are brittle
* No type safety
* Hard to debug
* Expression languages become mini-interpreters

### Recommended Alternatives

#### 1. Code-First Field Definitions (Preferred)

```dart
final fields = [
  FieldDefinition(id: 'user.name', type: 'text', label: 'Name'),
];
```

Use **string keys only as identifiers**, not data paths.

#### 2. Flat State Map (Critical Insight)

```dart
values = {
  'user.name': 'John',
  'user.age': 30,
}
```

✔ No nested mutation
✔ No deep copy issues
✔ Easy hide/show

#### 3. Derived View Models (Optional)

```dart
class UserVM {
  final String name;
  final int age;
}
```

Mapping happens **after submit**, not during form editing.

#### 4. Rule Composition in Dart

```dart
if (ctx.value('user.age')! < 18) {
  ctx.hide('driversLicense');
}
```

This is infinitely safer than JSON rules.

---

## 16. Final Architectural Verdict

* JSON is suitable only for **static layouts**
* Complex business flows must be **code-driven**
* Flat state + FormContext is the key insight
* MVVM + Riverpod enforces discipline

---

**This design intentionally avoids JSON-driven logic to prevent long-term technical debt while remaining fully dynamic and extensible.**

---

## 17. Rule Composition Helpers (Code-First DSL)

### Goal

Provide expressive, reusable rule building blocks **without** introducing a JSON or string-based DSL.

### Rule Contract

```dart
typedef FormRule = void Function(FormContext ctx);
```

### Rule Helpers

```dart
class Rules {
  static FormRule whenValueEquals(
    String fieldId,
    dynamic expected,
    FormRule thenRule,
  ) {
    return (ctx) {
      if (ctx.value(fieldId) == expected) {
        thenRule(ctx);
      }
    };
  }

  static FormRule show(String fieldId) => (ctx) => ctx.show(fieldId);
  static FormRule hide(String fieldId) => (ctx) => ctx.hide(fieldId);
  static FormRule enable(String fieldId) => (ctx) => ctx.enable(fieldId);
  static FormRule disable(String fieldId) => (ctx) => ctx.disable(fieldId);
}
```

### Usage in Transaction Service

```dart
class VehicleRulesService extends FormTransactionService {
  final List<FormRule> rules = [
    Rules.whenValueEquals(
      'category',
      'Vehicle',
      Rules.show('engineSize'),
    ),
  ];

  @override
  void onFieldChanged(ctx, fieldId, value) {
    for (final rule in rules) {
      rule(ctx);
    }
  }
}
```

---

## 18. Form Snapshot, Undo & Redo

### Why This Matters

* Complex business flows
* Regulatory / audit requirements
* "Back" navigation without data loss

### Snapshot Model

```dart
class FormSnapshot {
  final FormState state;
  const FormSnapshot(this.state);
}
```

### ViewModel Extension

```dart
class FormViewModel extends StateNotifier<FormState> {
  final _history = <FormSnapshot>[];
  final _future = <FormSnapshot>[];

  void snapshot() {
    _history.add(FormSnapshot(state));
    _future.clear();
  }

  void undo() {
    if (_history.isEmpty) return;
    _future.add(FormSnapshot(state));
    state = _history.removeLast().state;
  }

  void redo() {
    if (_future.isEmpty) return;
    _history.add(FormSnapshot(state));
    state = _future.removeLast().state;
  }
}
```

---

## 19. Analytics & Observability Hooks

### Use Cases

* Track field abandonment
* Measure time per step
* Identify confusing fields

### Hook Interface

```dart
abstract class FormAnalytics {
  void fieldChanged(String fieldId, dynamic value);
  void fieldFocused(String fieldId);
  void stepChanged(int step);
  void submitted(Map<String, dynamic> values);
}
```

### Injection Pattern

```dart
class FormContext {
  final FormAnalytics? analytics;
}
```

### Example

```dart
analytics?.fieldChanged(fieldId, value);
```

No analytics logic ever leaks into widgets.

---

## 20. Accessibility & Localization Contracts

### Accessibility Goals

* Screen reader friendly
* Predictable focus order
* Clear error announcements

### Contract

```dart
class AccessibilityConfig {
  final bool announceErrors;
  final bool autoFocusFirstError;

  const AccessibilityConfig({
    this.announceErrors = true,
    this.autoFocusFirstError = true,
  });
}
```

### Localization Strategy

* Package exposes **keys only**
* App supplies localized strings

```dart
labelKey: 'form.category.label'
```

---

## 21. Performance & Scalability Considerations

### Decisions That Scale

* Flat state map (O(1) access)
* No reflection
* No runtime parsing
* Riverpod diff-based rebuilds

### Anti-Patterns Avoided

* Global mutable state
* Widget-driven logic
* JSON expression evaluators

---

## 22. Testing Strategy

### Unit Tests

* ViewModel mutations
* Rule execution
* Validation

### Widget Tests

* Field rendering
* Hide/show behavior

### Service Tests

```dart
final ctx = FakeFormContext();
service.onFieldChanged(ctx, 'category', 'Vehicle');
expect(ctx.isVisible('engineSize'), true);
```

---

## 23. Final Notes

This architecture is intentionally:

* Boring in the engine
* Powerful in the app
* Predictable under pressure

If implemented as designed, this form builder can support **any business flow without rewrites or hacks**.

---

## 24. Rule Priority, Ordering & Conflict Resolution

### Why This Is Needed

As rules grow, conflicts may arise:

* Multiple rules toggling the same field
* Async rules racing with sync rules

### Rule Metadata

```dart
class FormRuleDefinition {
  final int priority; // higher runs later
  final FormRule rule;

  const FormRuleDefinition({
    required this.priority,
    required this.rule,
  });
}
```

### Execution Strategy

```dart
rules
  ..sort((a, b) => a.priority.compareTo(b.priority))
  ..forEach((r) => r.rule(ctx));
```

### Guideline

* **Lower priority** → structural rules (visibility)
* **Higher priority** → overrides & edge cases

---

## 25. Async Rules & Server Validation

### Use Cases

* Duplicate checks
* Credit validation
* External eligibility rules

### Async Rule Contract

```dart
typedef AsyncFormRule = Future<void> Function(FormContext ctx);
```

### ViewModel Execution

```dart
Future<void> executeAsyncRules() async {
  state = state.copyWith(isLoading: true);
  for (final rule in asyncRules) {
    await rule(context);
  }
  state = state.copyWith(isLoading: false);
}
```

### Server Error Mapping

```dart
ctx.setFieldError('email', 'Email already exists');
```

---

## 26. Form Orchestration (Cross-Form Flows)

### Scenario

* Registration → Profile → Verification
* Multiple forms, shared context

### Orchestrator

```dart
class FormOrchestrator {
  final Map<String, FormViewModel> forms;

  FormViewModel get(String id) => forms[id]!;
}
```

### Shared Context

```dart
orchestrator.get('profile').setValue('userId', id);
```

---

## 27. Visual Rule Debugging (Dev Mode)

### Goal

Make dynamic behavior **observable** during development.

### Debug Overlay

```dart
class RuleDebugEvent {
  final String rule;
  final String affectedField;
}
```

### Toggle

```dart
FormBuilder(
  debug: true,
)
```

### Output

* Rule fired
* Field affected
* Previous → new state

---

## 28. Security & Trust Boundaries

### Important Principle

**Never trust client-side rules alone**

### Strategy

* Client rules = UX
* Server rules = authority

### Submission Flow

```dart
validateLocal();
submit();
handleServerErrors();
```

---

## 29. Versioning & Package Evolution

### Rule

* Never break existing services
* Add capabilities via extension

### Pattern

```dart
abstract class FormTransactionServiceV2
  extends FormTransactionService {
  void onResume(FormContext ctx) {}
}
```

---

## 30. Example Folder Structure (Package)

```
lib/
 ├─ core/
 │   ├─ form_context.dart
 │   ├─ form_state.dart
 │   ├─ form_rule.dart
 │   └─ errors.dart
 ├─ mvvm/
 │   ├─ form_view_model.dart
 │   └─ form_providers.dart
 ├─ widgets/
 │   ├─ form_builder.dart
 │   └─ fields/
 ├─ theming/
 │   └─ form_theme.dart
 └─ services/
     └─ form_transaction_service.dart
```

---

## 31. Example Folder Structure (App)

```
lib/
 ├─ forms/
 │   ├─ registration_service.dart
 │   ├─ registration_fields.dart
 │   └─ registration_rules.dart
 ├─ providers/
 ├─ theme/
 └─ main.dart
```

---

## 32. Final Architectural Verdict

This design is:

* MVVM compliant
* Riverpod-native
* JSON-free
* Infinitely extensible
* Safe for enterprise usage

You are not building *a form builder*.
You are building **a domain-agnostic form runtime engine**.

That distinction is why this will scale.
