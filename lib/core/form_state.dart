import 'package:form_builder_package/core/errors.dart';

class FormState {
  final Map<String, dynamic> values;
  final Map<String, bool> visibility;
  final Map<String, bool> enabled;
  final List<FormError> errors;

  const FormState({
    required this.values,
    required this.visibility,
    required this.enabled,
    this.errors = const [],
  });

  factory FormState.initial() => const FormState(
        values: {},
        visibility: {},
        enabled: {},
        errors: [],
      );

  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, bool>? visibility,
    Map<String, bool>? enabled,
    List<FormError>? errors,
  }) {
    return FormState(
      values: values ?? this.values,
      visibility: visibility ?? this.visibility,
      enabled: enabled ?? this.enabled,
      errors: errors ?? this.errors,
    );
  }
}