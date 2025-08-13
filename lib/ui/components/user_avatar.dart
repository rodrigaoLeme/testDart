import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../share/utils/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final UserEntity user;
  final double size;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user.photoUrl != null && user.photoUrl!.isNotEmpty
            ? Colors.transparent
            : AppColors.red,
      ),
      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                user.photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
