import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/dto/rateDto.dart';
import 'package:bouh/services/rateService.dart';
import 'package:bouh/widgets/loading_overlay.dart';

class RateDoctorBottomSheet extends StatefulWidget {
  final String doctorId;
  final String appointmentId;

  const RateDoctorBottomSheet({
    super.key,
    required this.doctorId,
    required this.appointmentId,
  });

  static Future<void> show(
    BuildContext context, {
    required String doctorId,
    required String appointmentId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RateDoctorBottomSheet(
        doctorId: doctorId,
        appointmentId: appointmentId,
      ),
    );
  }

  @override
  State<RateDoctorBottomSheet> createState() => _RateDoctorBottomSheetState();
}

class _RateDoctorBottomSheetState extends State<RateDoctorBottomSheet> {
  static const Color _starColor = BColors.accent;

  int _selectedRating = 0;
  bool _isSubmitting = false;

  static const Map<int, String> _ratingMessages = {
  1: 'لم تكن تجربة جيدة',
  2: 'أقل من المتوقع',
  3: 'مقبولة',
  4: 'جيدة',
  5: 'ممتازة',
  };

  Future<void> _handleSubmit() async {
    if (_selectedRating < 1 || _selectedRating > 5) return;

    final doctorId = widget.doctorId.trim();
    final appointmentId = widget.appointmentId.trim();

    setState(() => _isSubmitting = true);
    try {
      await RateService().rateDoctor(
        rateDto: RateDto(
          doctorId: doctorId,
          rating: _selectedRating,
          appointmentId: appointmentId,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التقييم بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال التقييم: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: 40,
          bottom: MediaQuery.of(context).padding.bottom + 40,
        ),
        decoration: const BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              Text(
                'قيّم تجربتك مع الطبيب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: BColors.textDarkestBlue,
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'قيّم خدمة الطبيب خلال الموعد وتأثيرها على\nتجربة الطفل النفسية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: BColors.darkGrey,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                final isSelected = _selectedRating >= star;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedRating = star);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      size: 48,
                      color: _starColor,
                    ),
                  ),
                );
              }),
            ),
            if (_selectedRating > 0) ...[
              const SizedBox(height: 28),
              Center(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: BColors.accent.withOpacity(0.12),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: BColors.accent.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Text(
                      _ratingMessages[_selectedRating]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_selectedRating > 0 && !_isSubmitting)
                    ? _handleSubmit
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.secondary,
                  foregroundColor: BColors.textDarkestBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: BouhOvalLoadingIndicator(),
                      )
                    : const Text(
                        'ارسال التقييم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}