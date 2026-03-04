package com.bouh.backend.model.Dto;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;


@Data //setters,getters
@NoArgsConstructor
@AllArgsConstructor
public class doctorDto {
    @DocumentId
    private String doctorId;

    private String name;
    private String email;
    private String gender;
    private Double averageRating;
    private String areaOfKnowledge;
    private List<String> qualifications;
    private Integer yearsOfExperience;
    private String scfhsNumber;
    private String iban;
    private String profilePhotoURL;
    private String fcmToken;
    private String registrationStatus;
    }
