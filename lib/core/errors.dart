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