package com.bouh.backend.model.Dto;

import java.time.LocalDate;
import java.util.List;

import com.bouh.backend.model.Dto.DrawingAnalysis.drawingDto;

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
    private LocalDate dateOfBirth;
    private String gender;
    private List<drawingDto> drawings;
}
