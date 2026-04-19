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
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildInitialsAvatar();
            },
          ),
        ),
      );
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
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
