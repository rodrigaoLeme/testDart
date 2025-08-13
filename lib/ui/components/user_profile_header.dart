import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../share/utils/app_colors.dart';
import './user_avatar.dart';

class UserProfileHeader extends StatelessWidget {
  final UserEntity user;

  const UserProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(user: user, size: 88),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
