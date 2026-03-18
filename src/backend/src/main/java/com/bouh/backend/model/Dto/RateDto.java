package com.bouh.backend.model.Dto;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class RateDto {
    private String doctorId;
    private String appointmentId;
    private int rating;
}