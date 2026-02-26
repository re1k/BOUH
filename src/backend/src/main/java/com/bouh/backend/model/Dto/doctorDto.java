package com.bouh.backend.model.Dto;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
/**
 * DTO for reading doctor data from Firestore collection "doctors" (document by doctorId).
 * Source: doctors/{doctorId} — fields name, areaOfKnowledge, profilePhotoURL.
 * Used by DoctorRepo.findById to supply doctor info when building upcoming appointment response.
 */

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
    private String qualifications;
    private Integer yearsOfExperience;
    private String scfhsnumber;
    private String iban;
    private String profilePhotoURL;
    private String fcmToken;
    private String registrationStatus;
    private Object schedule; //later Schedule Dto
    }
