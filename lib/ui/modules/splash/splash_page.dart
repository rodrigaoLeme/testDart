import 'package:flutter/material.dart';
import 'package:seven_chat_app/share/utils/app_colors.dart';

import '../../../presentation/presenters/splash/splash_presenter.dart';
import '../../../share/ds/ds_logo.dart';
import '../../mixins/navigation_manager.dart';
import './splash_presenter.dart';

class SplashPage extends StatefulWidget {
  final SplashPresenter presenter;
  const SplashPage({super.key, required this.presenter});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with NavigationManager {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    widget.presenter.checkAccount();

    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    handleNavigation(widget.presenter.navigateToStream);

    return Material(
      child: Container(
        color: AppColors.darkBlue,
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 2200),
          curve: Curves.easeInOut,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Hero(
                  tag: 'logo',
                  child: DSLogo(
                    widht: 120,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Hero(
                  tag: 'text',
                  child: Text(
                    '7Chat.ai',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600, // SemiBold
                      fontSize: 24,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
