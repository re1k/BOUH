package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Qualificationrequestdto {
    private String requestId;
    private String doctorId;
    private String name;
    private String email;
    private String profilePhotoURL;
    private List<String> oldQualifications;
    private List<String> newQualifications;
}
