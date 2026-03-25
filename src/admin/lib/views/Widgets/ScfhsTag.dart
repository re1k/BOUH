import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

class ScfhsTagWidget extends StatelessWidget {
  final String value;

  const ScfhsTagWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BColors.softGrey,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: BColors.grey, width: 0.5),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: BColors.darkerGrey,
        ),
      ),
    );
  }
}
