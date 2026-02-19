import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:bouh/config/api_config.dart';
import 'package:bouh/services/payment/payment_service.dart';
import 'package:bouh/dto/payment/payment_request_dto.dart';

class PaymentSheet {
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    Stripe.publishableKey = ApiConfig.stripePublishableKey;
    await Stripe.instance.applySettings();

    _initialized = true;
  }

  static Future<String> show({required double total}) async {
    await _ensureInitialized();

    final amountInHalalah = (total * 100).round();

    final resp = await PaymentService().createPaymentIntent(
      PaymentRequestDto(
        name: "Appointment Booking",
        amount: amountInHalalah,
        currency: "sar",
      ),
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: resp.clientSecret,
        merchantDisplayName: "BOUH",
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return resp.paymentIntentId;
  }
}
