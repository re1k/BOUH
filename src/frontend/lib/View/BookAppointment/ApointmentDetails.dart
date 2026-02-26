import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'payment_sheet.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class AppointmentDetailsView extends StatelessWidget {
  const AppointmentDetailsView({
    super.key,
    required this.doctorName,
    required this.timeRange,
    required this.dateText,
    required this.childName,
    required this.price,
    required this.total,

    required this.doctorId,
    required this.childId,

    required this.timeSlotId,
    required this.caregiverId,
  });

  final String doctorName;
  final String timeRange;
  final String dateText;
  final String childName;
  final double price;
  final double total;

  final String doctorId;
  final String childId;

  final String timeSlotId;
  final String caregiverId; // later will use the session

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

                // Details card
                _Card(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: "الدكتور",
                        value: doctorName,
                        icon: Icons.favorite_border,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "الوقت",
                        value: timeRange,
                        icon: Icons.watch_later_outlined,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "التاريخ",
                        value: dateText,
                        icon: Icons.calendar_month_outlined,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                      _divider(),
                      _InfoRow(
                        label: "الطفل",
                        value: childName,
                        icon: Icons.person_outline,
                        iconBg: const Color(0xFFE9EEF3),
                        iconColor: BColors.primary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // thin line separator
                Container(
                  height: 1,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.20),
                ),

                const SizedBox(height: 26),

                // Price summary card
                _Card(
                  child: Column(
                    children: [
                      _PriceRow(label: "سعر الموعد", value: "${(price)} ريال"),
                      const SizedBox(height: 14),
                      _PriceRow(
                        label: "المجموع",
                        value: "${(total)} ريال",
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Pay button
                SizedBox(
                  width: 240,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final paymentIntentId = await PaymentSheet.show(
                          total: total,
                        );

                        if (!context.mounted) return;

                        await showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF4CAF50),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "تم الدفع بنجاح",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: BColors.accent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            54,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "حسناً",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        Navigator.pop(
                          context,
                          paymentIntentId,
                        ); // will be return the value fpr jano to store the appointment
                      } on stripe.StripeException catch (e) {
                        if (!context.mounted) return;

                        await showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFEBEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFE53935),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "لم تتم عملية الدفع",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    e.error.message ??
                                        "تم إلغاء الدفع أو حدث خطأ.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(0.55),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            54,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "حسناً",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        await showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFEBEE),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFE53935),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "خطأ غير متوقع",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "حدث خطأ أثناء معالجة الدفع.\nيرجى المحاولة مرة أخرى.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(0.55),
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            54,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "حسناً",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(54.52),
                      ),
                    ),
                    child: const Text(
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
