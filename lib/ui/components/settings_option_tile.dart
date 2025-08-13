import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../share/utils/app_colors.dart';

class SettingsOptionTile extends StatelessWidget {
  final String icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color titleColor;

  const SettingsOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset(
                  'lib/ui/assets/images/icons/$icon',
                  height: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
