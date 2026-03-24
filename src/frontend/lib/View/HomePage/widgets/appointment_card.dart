import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

enum AppointmentButtonType { start, cancel, none }

class AppointmentCard extends StatelessWidget {
  final String date;
  final String time;
  final String caregiverName;
  final String childName;
  final AppointmentButtonType? buttonType;

  /// When set, the action button (بدء/إلغاء) is tappable and triggers this callback.
  final VoidCallback? onActionTap;

  const AppointmentCard({
    super.key,
    required this.date,
    required this.time,
    required this.caregiverName,
    required this.childName,
    this.buttonType,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      height: 183,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: BColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تاريخ ووقت الموعد',
                    style: TextStyle(
                      fontFamily: 'Markazi Text',
                      fontSize: 14,
                      color: BColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _chip(Icons.access_time, time),
                        const SizedBox(width: 8),
                        _chip(Icons.calendar_today, date),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Markazi Text',
                        fontSize: 16,
                        color: BColors.textDarkestBlue,
                      ),
                      children: [
                        const TextSpan(
                          text: 'مقدم الرعاية : ',
                          style: TextStyle(
                            fontFamily: 'Markazi Text',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: caregiverName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Markazi Text',
                        fontSize: 16,
                        color: BColors.textDarkestBlue,
                      ),
                      children: [
                        const TextSpan(
                          text: 'للطفل : ',
                          style: TextStyle(
                            fontFamily: 'Markazi Text',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: childName),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        (buttonType == null ||
                            buttonType == AppointmentButtonType.none)
                        ? const SizedBox.shrink()
                        : (onActionTap != null
                              ? GestureDetector(
                                  onTap: onActionTap,
                                  behavior: HitTestBehavior.opaque,
                                  child: _actionButton(),
                                )
                              : _actionButton()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton() {
    if (buttonType == null || buttonType == AppointmentButtonType.none) {
      return const SizedBox.shrink();
    }

    final isStart = buttonType == AppointmentButtonType.start;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        color: isStart ? BColors.accent : Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isStart ? 'بدء' : 'إلغاء',
        style: const TextStyle(
          fontFamily: 'Markazi Text',
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  static Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BColors.softGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontFamily: 'Markazi Text', fontSize: 14),
          ),
        ],
      ),
    );
  }
}
