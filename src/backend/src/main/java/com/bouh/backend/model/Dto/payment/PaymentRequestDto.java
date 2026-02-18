package com.bouh.backend.model.Dto.payment;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor

public class PaymentRequestDto {
    @NotBlank
    private String name;

    @Min(1)
    private Long amount;

    @NotBlank
    private String currency;

}
