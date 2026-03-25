package com.bouh.backend.model.Dto.profiles;

import java.util.List;


import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

@Data
@AllArgsConstructor
@Builder
public class doctorProfileResponseDto {
    private String name; 
    private String gender; 
    private List<String> qualifications; 
    private Integer yearsOfExperience; 
    private String profilePhotoURL; 
    private String iban; 
    private String email;
    private String scfhsNumber;
    private String areaOfKnowledge;
}