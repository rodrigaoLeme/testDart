import 'dart:async';

import '../../ui/helpers/helpers.dart';

mixin UIErrorManager {
  final StreamController<UIError?> _mainErrorController =
      StreamController<UIError?>.broadcast();
  Stream<UIError?> get mainErrorStream => _mainErrorController.stream;
  set mainError(UIError? value) => _mainErrorController.sink.add(value);
}
