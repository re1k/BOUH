package com.bouh.backend.model.Dto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
// this class is for login auth the backend returns needed credanitels to the frontend
public class authDto {
    private String uid;
    private String role;
    private String registrationStatus; //For Doctors
}
