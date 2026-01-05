import 'form_context.dart';

typedef FormRule = void Function(FormContext ctx);

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