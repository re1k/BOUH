package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request DTO for add/edit child
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class ChildRequestDto {
    private String name;
    private String dateOfBirth; // YYYY-MM-DD
    private String gender;      // male/female (or Arabic)
}