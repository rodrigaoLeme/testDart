import 'package:flutter_modular/flutter_modular.dart';

import '../../routes_app.dart';
import '../pages/chat/chat_page_factory.dart';
import '../pages/faq/faq_page_factory.dart';
import '../pages/home/home_page_factory.dart';
import '../pages/login/login_page_factory.dart';
import '../pages/settings/settings_page_factory.dart';
import '../pages/splash/splash_page_factory.dart';

class CoreModule extends Module {
  @override
  void binds(i) {}

  @override
  void routes(r) {
    r.redirect('/', to: Routes.splash);

    r.child(
      Routes.splash,
      child: (_) => makeSplashPage(),
      transition: TransitionType.fadeIn,
    );

    r.child(
      Routes.home,
      child: (_) => makeHomePage(),
      transition: TransitionType.fadeIn,
    );

    r.child(
      Routes.login,
      child: (_) => makeLoginPage(),
      transition: TransitionType.fadeIn,
    );

    r.child(
      Routes.settings,
      child: (_) => makeSettingsPage(),
      transition: TransitionType.fadeIn,
    );

    r.child(
      '/faq',
      child: (_) => makeFAQPage(),
      transition: TransitionType.fadeIn,
    );

    r.child(
      Routes.chat,
      child: (context) {
        final args = r.args.data as Map<String, dynamic>? ?? {};
        return makeChatPage(
          conversationId: args['conversationId'] as String?,
          initialMessage: args['initialMessage'] as String?,
          autoSend: args['autoSend'] as bool? ?? false,
        );
      },
      transition: TransitionType.rightToLeft,
    );
  }
}
