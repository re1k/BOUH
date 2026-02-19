package com.bouh.backend.model.Dto;

import lombok.Data;

@Data
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
}
