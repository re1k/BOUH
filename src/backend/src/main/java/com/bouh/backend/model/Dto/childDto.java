package com.bouh.backend.model.Dto;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

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
    //private String dateOfBirth; // "2018-05-12"
    private LocalDate dateOfBirth;
    private String gender;
    private List<drawingDto> drawings;
}
