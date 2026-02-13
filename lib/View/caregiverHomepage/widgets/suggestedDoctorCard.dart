import 'package:flutter/material.dart';
import '../../../theme/base_themes/colors.dart';

/// Reusable suggested doctor card widget for the caregiver view.
///
/// Displays a single suggested doctor with:
/// -  profile image (or placeholder if [profileImage] is null)
/// - 5-star rating row (filled count = [rating], clamped to 0–5)
/// - Doctor name and specialty
///
/// Parameters:
/// - [name]: Full name of the doctor (e.g. "د. علي آل يحيى").
/// - [specialty]: Doctor's specialty or description (e.g. "خبير علاج القلق والتوتر").
/// - [rating]: Star rating from 0 to 5. Values outside this range are clamped internally.
/// - [profileImage]: Optional. When provided, displayed as circular avatar; otherwise placeholder is used.
///
/// Usage:
///   SuggestedDoctorCard(
///     name: 'د. علي آل يحيى',
///     specialty: 'خبير علاج القلق والتوتر',
///     rating: 4,
///   )
class SuggestedDoctorCard extends StatelessWidget {
  const SuggestedDoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.rating,
    this.profileImage,
  });

  /// Full name of the doctor.
  final String name;

  /// Doctor's specialty or description.
  final String specialty;

  /// Star rating from 0 to 5. Clamped internally to prevent invalid values.
  final int rating;

  /// Optional profile image. If null, the default placeholder is shown (circular, same size).
  final ImageProvider? profileImage;

  // --- Layout constants ---
  static const double _cardRadius = 16;
  static const double _cardBorderWidth = 1.5;
  static const double _avatarSize = 52;
  static const double _doctorCardPadding = 12;
  static const double _doctorCardGapStarsName = 6;
  static const double _doctorCardGapNameSubtitle = 3;
  static const double _doctorNameSubtitleOffsetY = -12;
  static const double _starSize = 15;
  static const double _starRowOffsetX = 4;
  static const double _starRowOffsetY = 13;
  static const double _gapBetweenAvatarAndContent = 16;
  static const double _starPaddingLeft = 2;

  /// Horizontal offset for avatar: positive = right, negative = left (in RTL, avatar is on the right).
  static const double _avatarOffsetX = -3;

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.clamp(0, 5);
    return Container(
      padding: const EdgeInsets.all(_doctorCardPadding),
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
        children: [
          Transform.translate(
            offset: const Offset(_avatarOffsetX, 0),
            child: _buildAvatar(),
          ),
          const SizedBox(width: _gapBetweenAvatarAndContent),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Transform.translate(
                    offset: const Offset(_starRowOffsetX, _starRowOffsetY),
                    child: _buildStarRow(clampedRating),
                  ),
                ),
                SizedBox(height: _doctorCardGapStarsName),
                Transform.translate(
                  offset: const Offset(0, _doctorNameSubtitleOffsetY),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Markazi Text',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: BColors.textDarkestBlue,
                        ),
                      ),
                      SizedBox(height: _doctorCardGapNameSubtitle),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(int filledCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: List.generate(5, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: const EdgeInsets.only(left: _starPaddingLeft),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            size: _starSize,
            color: filled ? BColors.accent : BColors.darkGrey,
          ),
        );
      }),
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

// USAGE EXAMPLE
//
//   SuggestedDoctorCard(
//     name: 'د. علي آل يحيى',
//     specialty: 'خبير علاج القلق والتوتر',
//     rating: 4,
//   )
//
// With optional profile image
