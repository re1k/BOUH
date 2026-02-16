package com.bouh.backend.service.serviceInterface.payment;

import com.bouh.backend.model.payment.PaymentRequestDto;
import com.bouh.backend.model.payment.PaymentResponseDto;

public interface PaymentService {
    PaymentResponseDto createPaymentIntent(PaymentRequestDto request);
}
