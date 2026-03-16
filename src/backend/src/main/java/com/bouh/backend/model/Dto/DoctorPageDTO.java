package com.bouh.backend.model.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor

public class DoctorPageDTO {
    private List<DoctorSearchDTO> doctors;
    private boolean hasMore;
}
