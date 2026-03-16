package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Data

public class DoctorSearchDTO {
    private String id;
    private String name;
    private String areaOfKnowledge;
    private double averageRating;
    private String profilePhotoURL;
}