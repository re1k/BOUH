package com.bouh.backend.model.Dto;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Data
public class DoctorManagement {
    private String uid;
    private String name;
    private String email;
    private String areaOfKnowledge;
    private List<String> qualifications;
    private int yearsOfExperience;
    private String iban;
    private String scfhsNumber;
    private String profilePhotoURL;

}