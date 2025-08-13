import 'dart:async';

mixin FormManager {
  final StreamController<bool> _isFormValidController =
      StreamController<bool>.broadcast();
  Stream<bool> get isFormValidStream => _isFormValidController.stream;
  set isFormValid(bool value) => _isFormValidController.sink.add(value);
}
