package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Data
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class appointmentDto {
    private String appointmentId;
    private String caregiverId;
    private String doctorId;
    private String childId;
    private String date;
    private String timeSlotId;
    private String meetingLink;
    private Long amount;
    private String status;
    private String paymentIntentId;
}
