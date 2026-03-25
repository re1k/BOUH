package com.bouh.backend.model.Dto.profiles;

import lombok.*;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class doctorUpdateDto {
    private String name; //editable
    private String gender; //editable
    private List<String> qualifications; //editable
    private Integer yearsOfExperience; //editable
    private String profilePhotoURL; //editable
    private String iban; //editable
}