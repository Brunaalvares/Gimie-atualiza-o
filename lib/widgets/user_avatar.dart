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

    final fallbackInitial = Center(
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

    // Center com width/heightFactor garante o tamanho fixo do círculo mesmo
    // quando o pai força largura total (ex.: filho direto de ListView/Column).
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: ClipOval(
          child: Container(
            color: backgroundColor,
            child: hasValidPhoto
                ? Image.network(
                    normalizedPhotoUrl,
                    // Preenche o círculo mantendo proporção (sem distorção):
                    // centraliza e recorta apenas o excedente das bordas.
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => fallbackInitial,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return fallbackInitial;
                    },
                  )
                : fallbackInitial,
          ),
        ),
      ),
    );
  }
}
