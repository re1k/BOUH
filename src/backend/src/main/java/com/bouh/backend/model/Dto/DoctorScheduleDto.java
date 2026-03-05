package com.bouh.backend.model.Dto;

import lombok.*;
import java.util.List;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class DoctorScheduleDto {
    private String date;               // "YYYY-MM-DD"
    private List<TimeSlotDto> timeSlots;
}