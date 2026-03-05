package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * What the backend returns to caregiver when listing doctors.
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DoctorSummaryDto {
    private String doctorID;
    private String name;
    private String areaOfKnowledge;
    private double averageRating;
    private String profilePhotoURL;
}