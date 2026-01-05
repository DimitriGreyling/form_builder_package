import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mvvm/form_view_model.dart';
import '../mvvm/form_providers.dart';
import 'errors.dart';

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