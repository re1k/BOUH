package com.bouh.backend.controller.payment;

import org.springframework.security.core.Authentication;

import com.bouh.backend.model.Dto.payment.PaymentRequestDto;
import com.bouh.backend.model.Dto.payment.PaymentResponseDto;
import com.bouh.backend.service.payment.PaymentService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {
    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    // Create PaymentIntent
    @PostMapping("/intent")
    public ResponseEntity<PaymentResponseDto> createPaymentIntent(
            @RequestBody PaymentRequestDto request, Authentication authentication) {
        String uid = authentication.getName();
        PaymentResponseDto response = paymentService.createPaymentIntent(request);
        return ResponseEntity.ok(response);
    }
}
