package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Child object returned to frontend
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class childDto {
    private String childID;
    private String name;
    private String dateOfBirth; // YYYY-MM-DD
    private String gender;    
}
