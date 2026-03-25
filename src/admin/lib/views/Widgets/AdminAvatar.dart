import 'package:flutter/material.dart';

class AdminAvatarWidget extends StatelessWidget {
  final String initials;
  final Color bg;
  final Color fg;
  final double size;
  final double fontSize;
  final String? photoUrl;

  const AdminAvatarWidget({
    super.key,
    required this.initials,
    required this.bg,
    required this.fg,
    this.size = 34,
    this.fontSize = 12,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      debugPrint('photoUrl: $photoUrl');
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: bg,
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
