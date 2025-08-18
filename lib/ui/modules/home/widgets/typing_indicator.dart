import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../share/utils/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final String text;
  final VoidCallback? onComplete;
  final int typingSpeed;

  const TypingIndicator({
    super.key,
    required this.text,
    this.onComplete,
    this.typingSpeed = 10,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  String _displayText = '';
  Timer? _typingTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _startTyping();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 🚀 MENOS FREQUENTE
      (timer) {
        if (_currentIndex < widget.text.length) {
          setState(() {
            // 🚀 ADICIONA MÚLTIPLOS CARACTERES POR VEZ
            final endIndex = (_currentIndex + widget.typingSpeed)
                .clamp(0, widget.text.length);
            _displayText = widget.text.substring(0, endIndex);
            _currentIndex = endIndex;
          });

          // 🚀 YIELD CONTROL PARA UI
          Future.delayed(Duration.zero);
        } else {
          _typingTimer?.cancel();
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      _displayText,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
        height: 1.4,
      ),
    );
  }
}
