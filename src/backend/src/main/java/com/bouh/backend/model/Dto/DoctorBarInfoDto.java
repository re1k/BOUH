package com.bouh.backend.model.Dto;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DoctorBarInfoDto {
   final String name;
   final double averageRating;
}
