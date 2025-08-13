import 'package:flutter/material.dart';
import 'package:seven_chat_app/ui/helpers/helpers.dart';

import '../../../../share/utils/app_colors.dart';

class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Animação dos pontos
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _dotsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeInOut,
    ));

    // Inicia as animações
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // indicador de pensando
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
              ),
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              padding: const EdgeInsets.all(0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    R.string.thinking,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pontos animados
                  AnimatedBuilder(
                    animation: _dotsAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.33;
                          final animationValue =
                              (_dotsAnimation.value - delay).clamp(0.0, 1.0);

                          // Calcula opacidade e escala baseado na animação
                          final opacity = animationValue < 0.5
                              ? animationValue * 2
                              : (1 - animationValue) * 2;
                          final scale = 0.8 + (opacity * 0.4);

                          return Container(
                            padding: const EdgeInsets.only(top: 7),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: opacity.clamp(0.3, 1.0),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
