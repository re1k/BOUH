package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class appointmentCreateRequestDto {
    private String doctorId;
    private String childId;
    private String date; // yyyy-MM-dd
    private Integer slotIndex; // 0..9
    private String paymentIntentId;
    private Long amount;
}