package com.bouh.backend.service.serviceInterface.payment;

import com.bouh.backend.model.Dto.payment.PaymentRequestDto;
import com.bouh.backend.model.Dto.payment.PaymentResponseDto;

public interface PaymentService {
    PaymentResponseDto createPaymentIntent(PaymentRequestDto request);
}
