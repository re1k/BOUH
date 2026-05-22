import 'package:flutter/widgets.dart';

/// Shared validation for account fields (email), names, IBAN suffix, and SCFHS.
/// Keeps login, registration, and profile edit consistent.
class ProfileFieldValidation {
  ProfileFieldValidation._();

  /// Trims ends and collapses consecutive whitespace to a single space (names).
  static String normalizePersonName(String? value) {
    if (value == null) return '';
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static void syncTextControllerToNormalizedPersonName(
    TextEditingController controller,
  ) {
    final normalized = normalizePersonName(controller.text);
    if (controller.text == normalized) return;
    controller.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
  static void syncTextControllerToExactText(
    TextEditingController controller,
    String text,
  ) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  //One qualification line (Arabic text, digits, spaces, and only `.` / `,` as extra symbols).
  static String normalizeQualificationLine(String? value) =>
      normalizePersonName(value);

  // When a line contains disallowed special characters (only `.` and `,` / `،` are allowed as punctuation).
  static const String qualificationsInvalidCharactersMessage =
      'يسمح بالفاصلة (، أو ,) والنقطة (.) فقط، دون أي رموز أخرى.';
  static const String qualificationsArabicOnlyMessage =
      'يرجى إدخال المؤهلات باللغة العربية فقط';
  static final RegExp _qualificationArabicDigitsSpacesAndPunctuation = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s\.,]+$',
  );

  /// Unified max length for caregiver name, doctor name (after honorific).
  static const int personDisplayNameMaxLength = 20;

  /// Child name (signup + children management).
  static const int childDisplayNameMinLength = 1;
  static const int childDisplayNameMaxLength = 10;

  static const int caregiverOrDoctorNameMaxLength = personDisplayNameMaxLength;
  static const int ibanSuffixDigitCount = 22;
  /// SCFHS-style registration: 2-digit year + 2-letter code + employee id (e.g. 08RM1).
  static const int scfhsMinLength = 5;
  static const int scfhsMaxLength = 13;

  /// Year (2 digits) + specialty code (2 letters) + alphanumeric employee sequence (1–9).
  static final RegExp scfhsRegistrationPattern = RegExp(
    r'^[0-9]{2}[A-Za-z]{2}[A-Za-z0-9]{1,9}$',
  );

  static const Set<String> _allowedEmailDomains = {
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'icloud.com',
    'live.com',
  };

  static const Set<String> _allowedEmailTlds = {
    'com',
    'net',
    'org',
    'edu',
    'gov',
    'sa',
  };

  /// Login / signup / reset — same rules everywhere.
  static String? accountEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    final domain = parts.last.toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    final tld = domainParts.last;
    final tldRegex = RegExp(r'^[a-zA-Z]{2,}$');
    if (!tldRegex.hasMatch(tld) || !_allowedEmailTlds.contains(tld)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    if (!_allowedEmailDomains.contains(domain)) {
      return 'يرجى استخدام بريد من مزوّد معتمد (مثل Gmail / Outlook)';
    }

    return null;
  }

  static final RegExp _caregiverNameLetters = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FFa-zA-Z\s]+$',
  );

  /// Letters + spaces in Arabic blocks (digits/symbols checked separately for doctors).
  static final RegExp _doctorNameArabicLettersAndSpaces = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s]+$',
  );

  /// Latin digits and Arabic-Indic / Persian digits — not allowed in names.
  static final RegExp nameDigitsLatinAndArabic = RegExp(
    r'[0-9\u0660-\u0669\u06F0-\u06F9]',
  );

  /// Tatweel, Arabic punctuation/symbols commonly typed by mistake.
  static final RegExp _doctorNameDisallowedSymbols = RegExp(
    r'[\u0640\u060C\u061B\u061F\u066A-\u066D\u06DD\u06DE\u06E9\uFD3C\uFD3D]',
  );

  static final RegExp _latinLetters = RegExp(r'[A-Za-z]');

  /// Qualification line validation:
  /// - English letters -> Arabic-only message
  /// - Other disallowed symbols -> punctuation message
  static String? qualificationLine(String? value) {
    final normalized = normalizeQualificationLine(value);
    if (normalized.isEmpty) return null;
    if (_latinLetters.hasMatch(normalized)) {
      return qualificationsArabicOnlyMessage;
    }
    if (!_qualificationArabicDigitsSpacesAndPunctuation.hasMatch(normalized)) {
      return qualificationsInvalidCharactersMessage;
    }
    return null;
  }

  static const String _doctorNameEnglishNotAllowedMessage =
      'يرجى إدخال الاسم باللغة العربية فقط';

  static const String _doctorNameInvalidCharsMessage =
      'لا يُسمح بإدخال أرقام أو رموز خاصة';

  /// Child name (signup / manage children): 1–10 characters after trim.
  static String? childDisplayName(String? value) {
    final normalized = normalizePersonName(value);
    if (normalized.length < childDisplayNameMinLength) {
      return 'يرجى إدخال اسم الطفل';
    }
    if (normalized.length > childDisplayNameMaxLength) {
      return 'يجب ألا يزيد اسم الطفل عن $childDisplayNameMaxLength أحرف';
    }
    return null;
  }

  /// Full caregiver display name (no honorific prefix).
  static String? caregiverDisplayName(String? value) {
    final normalized = normalizePersonName(value);
    if (normalized.isEmpty) {
      return 'يرجى إدخال اسم مقدم الرعاية';
    }
    if (nameDigitsLatinAndArabic.hasMatch(normalized) ||
        !_caregiverNameLetters.hasMatch(normalized)) {
      return _doctorNameInvalidCharsMessage;
    }
    return null;
  }

  /// Doctor name after the honorific (e.g. after "د. "): Arabic letters and spaces only — no digits or symbols.
  static String? doctorNameUserPart(String userEnteredTrimmed) {
    final normalized = normalizePersonName(userEnteredTrimmed);
    if (normalized.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (_latinLetters.hasMatch(normalized)) {
      return _doctorNameEnglishNotAllowedMessage;
    }
    if (nameDigitsLatinAndArabic.hasMatch(normalized)) {
      return _doctorNameInvalidCharsMessage;
    }
    if (_doctorNameDisallowedSymbols.hasMatch(normalized)) {
      return _doctorNameInvalidCharsMessage;
    }
    if (!_doctorNameArabicLettersAndSpaces.hasMatch(normalized)) {
      // Any remaining non-Arabic symbols/punctuation should be treated
      // as invalid characters (not as English letters).
      return _doctorNameInvalidCharsMessage;
    }
    return null;
  }

  /// 22 digits after the fixed country code (SA) on the IBAN.
  static String? ibanSuffixDigits(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'يرجى إدخال $ibanSuffixDigitCount رقمًا للآيبان بعد SA';
    }
    final digits = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (digits.length != ibanSuffixDigitCount ||
        !RegExp(r'^[0-9]{22}$').hasMatch(digits)) {
      return 'يجب إدخال $ibanSuffixDigitCount رقمًا للآيبان';
    }
    return null;
  }

  /// SCFHS / classification registration (alphanumeric, 5–13 chars).
  static String? scfhsRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم التخصص';
    }
    final normalized = value.trim().replaceAll(RegExp(r'\s'), '');
    if (normalized.length < scfhsMinLength ||
        normalized.length > scfhsMaxLength) {
      return 'رقم التخصص يجب أن يكون بين $scfhsMinLength و $scfhsMaxLength حرفًا';
    }
    if (!scfhsRegistrationPattern.hasMatch(normalized)) {
      return 'الصيغة: رقمان للسنة ثم حرفان (مثل RM) ثم رقم الموظف (مثال: 08RM1)';
    }
    return null;
  }
}
