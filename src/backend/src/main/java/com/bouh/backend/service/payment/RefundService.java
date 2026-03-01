package com.bouh.backend.service.payment;

import com.bouh.backend.model.Dto.payment.RefundRequestDto;
import com.bouh.backend.model.Dto.payment.RefundResponseDto;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.model.Refund;
import com.stripe.param.RefundCreateParams;
import org.springframework.stereotype.Service;

@Service
public class RefundService {

    public RefundResponseDto refund(RefundRequestDto request, String uid) {
        try {
            // 1) Retrieve PaymentIntent
            PaymentIntent intent = PaymentIntent.retrieve(request.getPaymentIntentId());

            // 2) Refund is done on the Charge
            String chargeId = intent.getLatestCharge();
            if (chargeId == null || chargeId.isBlank()) {
                throw new RuntimeException("Cannot refund: PaymentIntent has no latest_charge (not succeeded yet).");
            }

            // 3) Build refund params
            RefundCreateParams.Builder builder = RefundCreateParams.builder()
                    .setCharge(chargeId);

            // Partial refund if amount provided
            if (request.getAmount() != null) {
                builder.setAmount(request.getAmount());
            }

            Refund refund = Refund.create(builder.build());

            return new RefundResponseDto(
                    refund.getId(),
                    refund.getStatus(),
                    refund.getAmount(),
                    refund.getCurrency());

        } catch (StripeException e) {
            throw new RuntimeException("Stripe refund error: " + e.getMessage(), e);
        }
    }

}
