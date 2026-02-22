package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.DoctorSummaryDto;
import com.bouh.backend.service.doctors.DoctorsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class doctorsController {

    private final DoctorsService doctorsService;

    public doctorsController(DoctorsService doctorsService) {
        this.doctorsService = doctorsService;
    }

    /**
     * Caregiver - view list of doctors (approved only).
     * GET /api/caregiver/doctors
     */
  @GetMapping(value = "/caregiver/doctors", produces = "application/json")
    public ResponseEntity<List<DoctorSummaryDto>> getDoctorsForCaregiver() throws Exception {
        return ResponseEntity.ok(doctorsService.getDoctorsForCaregiverList());
    }
}