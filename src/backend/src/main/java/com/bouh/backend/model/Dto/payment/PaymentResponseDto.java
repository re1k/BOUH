package com.bouh.backend.model.Dto.payment;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor

public class PaymentResponseDto {
    private String paymentIntentId;
    private String clientSecret;

}
