package com.bouh.backend.service.serviceImp.payment;

import com.bouh.backend.model.Dto.payment.PaymentRequestDto;
import com.bouh.backend.model.Dto.payment.PaymentResponseDto;
import com.bouh.backend.service.serviceInterface.payment.PaymentService;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import org.springframework.stereotype.Service;

@Service
public class PaymentServiceImpl implements PaymentService {

    @Override
    public PaymentResponseDto createPaymentIntent(PaymentRequestDto request) {

        try {

            PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                    .setAmount(request.getAmount())
                    .setCurrency(request.getCurrency().toLowerCase())
                    .setDescription(request.getName())
                    .addPaymentMethodType("card")
                    .putMetadata("service_name", request.getName())
                    .build();

            PaymentIntent intent = PaymentIntent.create(params);

            return new PaymentResponseDto(intent.getId(), intent.getClientSecret());

        } catch (StripeException e) {

            throw new RuntimeException("Stripe error: " + e.getMessage(), e);
        }
    }
}