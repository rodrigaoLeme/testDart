import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? iconAsset;
  final Color iconColor;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.iconAsset,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 24, color: iconColor)
            else if (iconAsset != null)
              Image.asset(iconAsset!, width: 24, height: 24),
            const SizedBox(width: 27),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
