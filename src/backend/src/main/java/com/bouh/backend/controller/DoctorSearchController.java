package com.bouh.backend.controller;

import org.springframework.security.core.Authentication;

import com.bouh.backend.model.Dto.DoctorPageDTO;
import com.bouh.backend.model.Dto.DoctorSearchDTO;
import com.bouh.backend.service.DoctorSearchService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/doctors")
public class DoctorSearchController {
    private final DoctorSearchService doctorSearchService;

    public DoctorSearchController(DoctorSearchService doctorSearchService) {
        this.doctorSearchService = doctorSearchService;
    }

    @GetMapping("/top-rated")
    public ResponseEntity<DoctorPageDTO> getTopRatedDoctors(
            @RequestParam(required = false) String lastDoctorId,
            Authentication authentication)
            throws ExecutionException, InterruptedException {

        DoctorPageDTO page = doctorSearchService.getTopRatedDoctors(lastDoctorId);
        return ResponseEntity.ok(page);
    }

    @GetMapping("/search")
    public ResponseEntity<List<DoctorSearchDTO>> searchDoctors(
            @RequestParam String name,
            Authentication authentication)
            throws ExecutionException, InterruptedException {

        List<DoctorSearchDTO> results = doctorSearchService.searchByName(name);
        return ResponseEntity.ok(results);
    }

    @GetMapping("/filter")
    public ResponseEntity<List<DoctorSearchDTO>> filterByArea(
            @RequestParam String areaOfKnowledge,
            Authentication authentication)
            throws ExecutionException, InterruptedException {

        List<DoctorSearchDTO> results = doctorSearchService.filterByAreaOfKnowledge(areaOfKnowledge);
        return ResponseEntity.ok(results);
    }
}
