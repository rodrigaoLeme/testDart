import '../../../ui/mixins/navigation_data.dart';

abstract class SplashPresenter {
  Stream<NavigationData?> get navigateToStream;
  Future<void> checkAccount({int durationInSeconds});
  Future<void> preloadAppData();
}
