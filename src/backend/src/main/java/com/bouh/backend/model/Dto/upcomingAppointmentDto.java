package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * API response DTO for GET /api/appointments/upcoming/{caregiverId}.
 * Sent to frontend only. Resolved fields (doctorName, childName, startTime, endTime) + meetingLink for انضمام.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class upcomingAppointmentDto {
    private String appointmentId;
    private String date;
    private String startTime;
    private String endTime;
    private String doctorName;
    private String doctorAreaOfKnowledge;
    private String doctorProfilePhotoURL;
    private String childName;
    private String status;
    private String meetingLink;
    private String paymentIntentId;
}
