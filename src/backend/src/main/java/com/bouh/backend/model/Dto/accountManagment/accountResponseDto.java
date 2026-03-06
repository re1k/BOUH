package com.bouh.backend.model.Dto.accountManagment;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class accountResponseDto {
    private boolean success;
    private String code;
    private String message;
}
