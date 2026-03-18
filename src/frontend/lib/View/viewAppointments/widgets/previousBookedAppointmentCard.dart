import 'package:flutter/material.dart';
import '../../../theme/base_themes/colors.dart';

/// Previous booked appointment card with attendance status.
///
/// Shows: child name badge (top-right), avatar, doctor name, specialty,
/// optional rating stars (only when [attendanceStatus] is "تم الحضور"),
/// date/time, and a left-side pill badge for attendance.
///
/// [attendanceStatus]: "تم الحضور" (green badge, show stars) or "لم يتم الحضور" (red badge, no stars).
/// [rating]: Optional; only used when attendance is "تم الحضور".
class PreviousBookedAppointmentCard extends StatelessWidget {
  const PreviousBookedAppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.childName,
    required this.date,
    required this.time,
    required this.attendanceStatus,
    this.profileImage,
    this.showRateButton = false,
    this.onRateTap,
  });

  final String doctorName;
  final String specialty;
  final String childName;
  final String date;
  final String time;

  /// "تم الحضور" or "لم يتم الحضور".
  final String attendanceStatus;
  final ImageProvider? profileImage;

  /// <Rating feature> When true, show the rate button (instead of stars).
  final bool showRateButton;
  final VoidCallback? onRateTap;

  // Match AppointmentCard exactly
  static const double _cardRadius = 16;
  static const double _cardPadding = 16;
  static const double _cardBorderWidth = 1.5;
  static const double _avatarSize = 52;
  static const double _avatarOffsetY = 6;
  static const double _joinButtonWidth = 84;
  static const double _joinButtonHeight = 20;
  static const double _chipRight = 20;
  static const Color _chipBackground = Color(0xFFA6BECB);
  static const Color _attendedBg = Color(0xFF4CAF50);
  static const Color _notAttendedBg = Color(0xFFE85D4F);
  static const double _rateOffsetY = 4;

  static const double _dateTimeTextOffsetY = 1;
  static const double _nameSpecialtyOffsetY = 4;

  bool get _isAttended => attendanceStatus == 'تم الحضور';

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [_buildCardContent(), _buildChildNameBadge()],
    );
  }

  Widget _buildCardContent() {
    return Container(
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: const Color(0xFFE4E6ED),
          width: _cardBorderWidth,
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, _avatarOffsetY),
            child: _buildAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, _nameSpecialtyOffsetY),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName,
                              style: TextStyle(
                                fontFamily: 'Markazi Text',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BColors.textDarkestBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: TextStyle(
                                fontFamily: 'Markazi Text',
                                fontSize: 13,
                                color: BColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // <Rating feature> Button appears only when parent allows it.
                      if (_isAttended && showRateButton && onRateTap != null) ...[
                        const SizedBox(width: 8),
                        Transform.translate(
                          offset: const Offset(0, _rateOffsetY),
                          child: _buildRateButton(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildDateTimeRow()),
                    const SizedBox(width: 0),
                    _buildStatusButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// <Rating feature> Orange rate button (uses primary accent color).
  Widget _buildRateButton() {
    return GestureDetector(
      onTap: onRateTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _joinButtonWidth,
        height: _joinButtonHeight,
        decoration: BoxDecoration(
          color: BColors.accent,
          borderRadius: BorderRadius.circular(_joinButtonHeight / 2),
        ),
        alignment: Alignment.center,
        child: const Text(
          'قيم الموعد',
          style: TextStyle(
            fontFamily: 'Markazi Text',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: BColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeRow() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.calendar_today, size: 14, color: BColors.darkGrey),
          const SizedBox(width: 6),
          Transform.translate(
            offset: const Offset(0, _dateTimeTextOffsetY),
            child: Text(
              date,
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 12,
                color: BColors.darkGrey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.access_time, size: 14, color: BColors.darkGrey),
          const SizedBox(width: 6),
          Transform.translate(
            offset: const Offset(0, _dateTimeTextOffsetY),
            child: Text(
              time,
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 12,
                color: BColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Same size and position as "انضمام" in AppointmentCard; only label and color differ.
  /// White background, card-matching border, text color indicates status (green/red).
  Widget _buildStatusButton() {
    final textColor = _isAttended ? _attendedBg : _notAttendedBg;
    return Container(
      width: _joinButtonWidth,
      height: _joinButtonHeight,
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: const Color(0xFFE4E6ED),
          width: _cardBorderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        attendanceStatus,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildChildNameBadge() {
    return Positioned(
      top: -2,
      right: _chipRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: _chipBackground,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Text(
          childName,
          style: TextStyle(
            fontFamily: 'Markazi Text',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BColors.white,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (profileImage != null) {
      return ClipOval(
        child: SizedBox(
          width: _avatarSize,
          height: _avatarSize,
          child: Image(image: profileImage!, fit: BoxFit.cover),
        ),
      );
    }
    return ClipOval(
      child: Container(
        width: _avatarSize,
        height: _avatarSize,
        color: BColors.softGrey,
        child: Icon(
          Icons.person,
          color: BColors.darkGrey,
          size: _avatarSize * 0.5,
        ),
      ),
    );
  }
}
