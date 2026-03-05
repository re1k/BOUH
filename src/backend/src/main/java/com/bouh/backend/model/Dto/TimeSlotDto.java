package com.bouh.backend.model.Dto;

import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class TimeSlotDto {
    private String timeSlotID;
    private String startTime;
    private String endTime;
    private String status; // available / booked
}