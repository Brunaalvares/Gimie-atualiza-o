import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.radius,
    this.backgroundColor = const Color(0xFF8B7FB8),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPhotoUrl = photoUrl?.trim();
    final hasValidPhoto =
        normalizedPhotoUrl != null && normalizedPhotoUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage: hasValidPhoto ? NetworkImage(normalizedPhotoUrl) : null,
      onForegroundImageError: hasValidPhoto ? (_, __) {} : null,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: textStyle ??
            TextStyle(
              fontSize: radius * 0.6,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
