import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';
import 'AdminAvatar.dart';
import 'ScfhsTag.dart';

class DoctorDetailDialog extends StatelessWidget {
  final String name;
  final String email;
  final String specialty;
  final String qualifications;
  final String yearsOfExperience;
  final String scfhsNumber;
  final String iban;
  final Color avatarBg;
  final Color avatarFg;
  final String? photoUrl;

  const DoctorDetailDialog({
    super.key,
    required this.name,
    required this.email,
    required this.specialty,
    required this.qualifications,
    required this.yearsOfExperience,
    required this.scfhsNumber,
    required this.iban,
    required this.avatarBg,
    required this.avatarFg,
    this.photoUrl,
  });

  String get _initials {
    final parts = name.replaceAll('د. ', '').trim().split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: BColors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تفاصيل الطبيب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: BColors.softGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: BColors.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AdminAvatarWidget(
                          initials: _initials,
                          bg: avatarBg,
                          fg: avatarFg,
                          size: 64,
                          fontSize: 24,
                          photoUrl: photoUrl,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: BColors.textDarkestBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(
                                fontSize: 15,
                                color: BColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'مجال المعرفة', value: specialty),
                    _InfoRow(label: 'سنوات الخبرة', value: yearsOfExperience),
                    _InfoRow(label: 'المؤهلات العلمية', value: qualifications),
                    _InfoRow(label: 'البريد الإلكتروني', value: email),
                    _InfoRow(label: 'رقم التخصص', value: scfhsNumber),
                    _InfoRow(label: 'رقم الايبان', value: iban),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final bool mono;
  final bool ltr;
  final Widget? child;

  const _InfoRow({
    required this.label,
    this.value,
    this.valueColor,
    this.mono = false,
    this.ltr = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BColors.grey, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
            ),
          ),
          Expanded(
            child:
                child ??
                Text(
                  value ?? '',
                  textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? BColors.textDarkestBlue,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
