import 'dart:async';

import '../../ui/mixins/navigation_data.dart';

mixin NavigationManager {
  final StreamController<NavigationData> _navigateToController =
      StreamController<NavigationData>.broadcast();
  Stream<NavigationData?> get navigateToStream => _navigateToController.stream;
  set navigateTo(NavigationData value) => _navigateToController.sink.add(value);
}
