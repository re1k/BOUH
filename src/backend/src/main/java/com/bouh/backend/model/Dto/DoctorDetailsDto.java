package com.bouh.backend.model.Dto;

import lombok.*;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
public class DoctorDetailsDto {
    private String doctorID;
    private String name;
    private String email;
    private String gender;
    private Double averageRating;
    private String areaOfKnowledge;
    private String qualifications;
    private Integer yearsOfExperience;
    private String profilePhotoURL;
}