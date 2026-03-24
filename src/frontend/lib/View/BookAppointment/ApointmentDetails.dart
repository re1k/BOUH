import 'package:bouh/View/caregiverHomepage/caregiverHomepage.dart';
import 'package:bouh/View/caregiverHomepage/caregivernavbar.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'payment_sheet.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/dto/bookAppointmentRequestDto.dart';
import 'package:bouh/View/viewAppointments/bookedAppointmentsUpcoming.dart';
import 'package:bouh/authentication/AuthSession.dart';

class AppointmentDetailsView extends StatefulWidget {
  const AppointmentDetailsView({
    super.key,
    required this.doctorName,
    required this.timeRange,
    required this.dateText,
    required this.dateIso,
    required this.childName,
    required this.price,
    required this.total,
    required this.doctorId,
    required this.childId,
    required this.timeSlotId,
    required this.slotIndex,
    required this.caregiverId,
  });

  final String doctorName;
  final String timeRange;
  final String dateText;
  final String dateIso;
  final String childName;
  final double price;
  final double total;

  final String doctorId;
  final String childId;

  final String timeSlotId;
  final int slotIndex;
  final String caregiverId;

  @override
  State<AppointmentDetailsView> createState() => _AppointmentDetailsViewState();
}

class _AppointmentDetailsViewState extends State<AppointmentDetailsView> {
  final AppointmentsService _appointmentsService = AppointmentsService();
  bool _isSubmitting = false;

  Future<void> _handlePaymentAndBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final paymentIntentId = await PaymentSheet.show(total: widget.total);

      if (!mounted) return;

      await _appointmentsService.createAppointment(
        BookAppointmentRequestDto(
          doctorId: widget.doctorId,
          childId: widget.childId,
          date: widget.dateIso,
          slotIndex: widget.slotIndex,
          paymentIntentId: paymentIntentId,
          amount: (widget.total * 100).round(),
        ),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: BColors.white,
            actionsAlignment: MainAxisAlignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تم الحجز بنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: const Text(
              'تم الدفع وتأكيد الموعد بنجاح.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: BColors.darkGrey,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const CaregiverNavbar(
            initialIndex: 2,
            initialAppointmentsSubIndex: 1,
            initialBookedSubIndex: 0,
          ),
        ),
        (route) => false,
      );
    } on stripe.StripeException {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: BColors.white,
            actionsAlignment: MainAxisAlignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'لم تتم عملية الدفع',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: const Text(
              'تم إلغاء الدفع أو حدث خطأ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: BColors.darkGrey,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.validationError,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceFirst('Exception: ', '');

      await showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: BColors.white,
            actionsAlignment: MainAxisAlignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تعذر إتمام الحجز',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: BColors.darkGrey,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.validationError,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, size: 30),
                    ),
                    const SizedBox(width: 63),
                    Text(
                      "تفاصيل الموعد",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.78),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 26),

                _Card(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: "الطبيب",
                        value: widget.doctorName,
                        icon: Icons.favorite_border,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "الوقت",
                        value: widget.timeRange,
                        icon: Icons.watch_later_outlined,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "التاريخ",
                        value: widget.dateText,
                        icon: Icons.calendar_month_outlined,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "الطفل",
                        value: widget.childName,
                        icon: Icons.person_outline,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.20),
                ),

                const SizedBox(height: 26),

                _Card(
                  child: Column(
                    children: [
                      _PriceRow(
                        label: "سعر الموعد",
                        value: "${widget.price} ريال",
                      ),
                      const SizedBox(height: 14),
                      _PriceRow(
                        label: "المجموع",
                        value: "${widget.total} ريال",
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: 240,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handlePaymentAndBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(54.52),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "دفع",
                            style: TextStyle(
                              fontSize: 20.44,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.black.withOpacity(0.18),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ],
        ),
        const SizedBox(width: 100),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
