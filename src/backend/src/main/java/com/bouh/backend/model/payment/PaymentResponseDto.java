package com.bouh.backend.model.payment;

public class PaymentResponseDto {
    private String paymentIntentId;
    private String clientSecret;

    public PaymentResponseDto(String paymentIntentId, String clientSecret) {
        this.paymentIntentId = paymentIntentId;
        this.clientSecret = clientSecret;
    }

    public String getPaymentIntentId() {
        return paymentIntentId;
    }

    public String getClientSecret() {
        return clientSecret;
    }
}
