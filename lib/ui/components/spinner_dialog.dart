import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:seven_chat_app/presentation/mixins/loading_manager.dart';

void hideLoading(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }
}

Future<void> showLoading(BuildContext context, LoadingData data) async {
  Future.delayed(Duration.zero, () async {
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4), // desfoca fundo
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                //color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  });
}
