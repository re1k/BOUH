package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.DoctorDetailsDto;
import com.bouh.backend.model.Dto.DoctorScheduleDto;
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
    // Doctor details for DoctorDetailsView
    @GetMapping(value = "/caregiver/doctors/{doctorId}", produces = "application/json")
    public ResponseEntity<DoctorDetailsDto> getDoctorDetails(@PathVariable String doctorId) throws Exception {
        return ResponseEntity.ok(doctorsService.getDoctorDetails(doctorId));
    }

    // Schedule for booking tab
    @GetMapping(value = "/caregiver/doctors/{doctorId}/schedule", produces = "application/json")
    public ResponseEntity<DoctorScheduleDto> getDoctorScheduleByDate(
            @PathVariable String doctorId,
            @RequestParam String date
    ) throws Exception {
        return ResponseEntity.ok(doctorsService.getDoctorScheduleByDate(doctorId, date));
    }
}