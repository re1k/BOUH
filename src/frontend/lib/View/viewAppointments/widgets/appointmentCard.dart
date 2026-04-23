import 'package:flutter/material.dart';
import '../../../theme/base_themes/colors.dart';

/// Reusable appointment card widget for the caregiver view.
///
/// Displays a single appointment with:
/// - Doctor name and specialty
/// - Child name badge (top-right; expands left only when name is long)
/// - Date and time
/// - Optional profile image (or placeholder if none)
/// - "انضمام" (Join) action button
///
/// Parameters:
/// - [doctorName]: Full name of the doctor (e.g. "د. موسى السبيعي").
/// - [specialty]: Doctor's specialty or session topic (e.g. "التعامل مع العزلة").
/// - [childName]: Name shown in the top-right badge (e.g. "بسام").
/// - [date]: Appointment date string (e.g. "8/12/2025").
/// - [time]: Appointment time string (e.g. "8:00 - 8:30 مساء").
/// - [profileImage]: Optional. When provided, displayed as circular avatar; otherwise placeholder is used.
///
/// Usage:
///   AppointmentCard(
///     doctorName: 'د. موسى السبيعي',
///     specialty: 'التعامل مع العزلة',
///     childName: 'بسام',
///     date: '8/12/2025',
///     time: '8:00 - 8:30 مساء',
///   )
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.childName,
    required this.date,
    required this.time,
    this.profileImage,
    this.actionLabel,
    this.actionColor,
    this.onActionTap,
  });

  /// Full name of the doctor.
  final String doctorName;

  /// Doctor's specialty or session description.
  final String specialty;

  /// Name of the child; shown in the badge at top-right. Badge expands left only when long.
  final String childName;

  /// Appointment date string.
  final String date;

  /// Appointment time string.
  final String time;

  /// Optional profile image. If null, the default placeholder is shown (circular, same size).
  final ImageProvider? profileImage;

  /// Optional action button label (e.g. "انضمام" or "الغاء"). Default: "انضمام".
  final String? actionLabel;

  /// Optional action button background color. Default: [BColors.accent].
  final Color? actionColor;

  /// Optional: called when the action button is tapped (e.g. open meeting link for انضمام).
  final VoidCallback? onActionTap;

  // --- Layout constants (must match original card exactly) ---
  static const double _cardRadius = 16;
  static const double _cardPadding = 16;
  static const double _cardBorderWidth = 1.5;
  static const double _avatarSize = 52;
  static const double _avatarOffsetY = 6;
  static const double _joinButtonWidth = 70;
  static const double _joinButtonHeight = 20;
  static const double _chipRight = 20;

  /// Child name badge background (e.g. "بسام" chip).
  static const Color _chipBackground = Color(0xFFA6BECB);

  static const double _dateTimeTextOffsetY = 1;

  /// Vertical offset for doctor name and specialty (moves them down slightly).
  static const double _nameSpecialtyOffsetY = 4;

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
                const SizedBox(height: 12),
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.rtl,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: BColors.darkGrey,
                            ),
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
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: BColors.darkGrey,
                            ),
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
                      ),
                    ),
                    const SizedBox(width: 0),
                    if (actionLabel != null && actionLabel!.isNotEmpty)
                      _buildJoinButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Child name badge: fixed right edge (right: 20), expands to the left only when text is long.
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
    return ClipOval(
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: Image(
          image:
              profileImage ??
              const AssetImage('assets/images/default_ProfileImage.png'),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/default_ProfileImage.png',
            width: _avatarSize,
            height: _avatarSize,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    if (actionLabel == null) {
      return const SizedBox.shrink();
    }

    final label = actionLabel!;
    final color = actionColor ?? BColors.accent;

    final child = Container(
      width: _joinButtonWidth,
      height: _joinButtonHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_joinButtonHeight / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: BColors.white,
        ),
      ),
    );

    if (onActionTap != null) {
      return GestureDetector(
        onTap: onActionTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return child;
  }
}

// USAGE EXAMPLE
//
// Create a single appointment card with required parameters:
//
//   AppointmentCard(
//     doctorName: 'د. موسى السبيعي',
//     specialty: 'التعامل مع العزلة',
//     childName: 'بسام',
//     date: '8/12/2025',
//     time: '8:00 - 8:30 مساء',
//   )
