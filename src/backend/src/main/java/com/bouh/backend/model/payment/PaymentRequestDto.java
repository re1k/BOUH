package com.bouh.backend.model.payment;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public class PaymentRequestDto {
    @NotBlank
    private String name;

    @Min(1)
    private Long amount;

    @NotBlank
    private String currency;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Long getAmount() {
        return amount;
    }

    public void setAmount(Long amount) {
        this.amount = amount;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }
}
