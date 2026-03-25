import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  final String? tooltip;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: BColors.grey, width: 0.5),
        ),
        child: Icon(icon, size: 15, color: fg),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        preferBelow: false,
        textStyle: const TextStyle(fontSize: 12, color: BColors.white),
        decoration: BoxDecoration(
          color: BColors.textDarkestBlue,
          borderRadius: BorderRadius.circular(6),
        ),
        child: button,
      );
    }

    return button;
  }
}

class ActionTextButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;

  const ActionTextButton({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class DeleteButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const DeleteButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.delete_outline, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: BColors.darkGrey,
        side: const BorderSide(color: BColors.grey, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
