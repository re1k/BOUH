import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Typography constants using Markazi Text font (Arabic-friendly)
class BTypography {
  BTypography._();

  /// Font family name
  static const String fontFamily = 'Markazi Text';

  /// Get Markazi Text style with custom properties
  static TextStyle markazi({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.normal,
    Color color = BColors.textBlack,
    double? height,
  }) {
    return GoogleFonts.markaziText(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Predefined text styles

  /// Page title - large bold text
  static TextStyle get pageTitle => GoogleFonts.markaziText(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: BColors.textDarkestBlue,
  );

  /// Section title - medium bold text
  static TextStyle get sectionTitle => GoogleFonts.markaziText(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: BColors.textDarkestBlue,
  );

  /// Button text - medium weight
  static TextStyle get buttonText => GoogleFonts.markaziText(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: BColors.white,
  );

  /// Button text secondary - for outlined buttons
  static TextStyle get buttonTextSecondary => GoogleFonts.markaziText(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: BColors.primary,
  );

  /// Body text - regular
  static TextStyle get bodyText => GoogleFonts.markaziText(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: BColors.textBlack,
  );

  /// Label text - small
  static TextStyle get labelText => GoogleFonts.markaziText(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: BColors.darkerGrey,
  );

  /// Label text - medium
  static TextStyle get labelTextMedium => GoogleFonts.markaziText(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: BColors.darkerGrey,
  );

  /// Dropdown hint text
  static TextStyle get dropdownHint => GoogleFonts.markaziText(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: BColors.darkGrey,
  );

  static TextStyle get dropdownSelected => TextStyle(
    fontFamily: 'Markazi Text',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: BColors.textDarkestBlue,
  );
}
