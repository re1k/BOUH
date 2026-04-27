class SlotConfig {
  // Afternoon block (indexes 0–9)
  static const int afternoonStartHour = 16;
  static const int afternoonStartMinute = 0;
  static const int afternoonSlotCount = 10;
  static const int slotMinutes = 30;

  // Morning test slots (indexes 10, 11) for demo
  static const bool morningEnabled = true;
  static const int morningStartHour = 9;
  static const int morningStartMinute = 0;
  static const int morningSlotCount = 2;

  static int get slotCount =>
      afternoonSlotCount + (morningEnabled ? morningSlotCount : 0);

  static bool isMorningSlot(int index) =>
      morningEnabled && index >= afternoonSlotCount;

  static (int hour, int minute) slotStart(int index) {
    if (isMorningSlot(index)) {
      final morningIndex = index - afternoonSlotCount;
      final total =
          morningStartHour * 60 +
          morningStartMinute +
          morningIndex * slotMinutes;
      return (total ~/ 60, total % 60);
    }
    final total =
        afternoonStartHour * 60 + afternoonStartMinute + index * slotMinutes;
    return (total ~/ 60, total % 60);
  }

  static (int hour, int minute) slotEnd(int index) {
    final (h, m) = slotStart(index);
    final total = h * 60 + m + slotMinutes;
    return (total ~/ 60, total % 60);
  }

  static String _fmt(int h, int m) {
    final hh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hh:${m.toString().padLeft(2, '0')}';
  }

  static String amPmSuffix(int index) {
    final (hour, _) = slotStart(index);
    return hour < 12 ? 'صباحًا' : 'مساءً';
  }

  static String slotLabel(int index) {
    final (h1, m1) = slotStart(index);
    final (h2, m2) = slotEnd(index);
    return '${_fmt(h1, m1)} - ${_fmt(h2, m2)} ${amPmSuffix(index)}';
  }

  static String slotStartText(int index) {
    final (h, m) = slotStart(index);
    return '${_fmt(h, m)}';
  }
}
