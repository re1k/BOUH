package com.bouh.backend.model.Dto;
import com.google.cloud.Timestamp;

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
    private String timeSlotId;
    private Timestamp startDateTime;
    private String endTime;
    private String meetingLink;
    private Long amount;
    /** 0 = absent, 1 = present. */
    private Integer status;
    private String paymentIntentId;
    private Boolean rated;
}
