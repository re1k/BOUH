package com.bouh.backend.model.Dto.profiles;
import lombok.Builder;
import lombok.Data;

@Data //setters,getters
@Builder
public class caregiverProfileResponseDto {
    private String name; //editable
    private String email;
}