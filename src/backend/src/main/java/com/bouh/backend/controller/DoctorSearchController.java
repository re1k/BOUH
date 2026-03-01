package com.bouh.backend.controller;

import org.springframework.security.core.Authentication;

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

    @GetMapping("/search")
    public ResponseEntity<List<DoctorSearchDTO>> searchDoctors(
            @RequestParam String name, Authentication authentication) throws ExecutionException, InterruptedException {
        String uid = authentication.getName();

        List<DoctorSearchDTO> results = doctorSearchService.searchByName(name, uid);
        return ResponseEntity.ok(results);
    }

    @GetMapping("/top-rated")
    public ResponseEntity<List<DoctorSearchDTO>> getTopRatedDoctors(Authentication authentication)
            throws ExecutionException, InterruptedException {
        String uid = authentication.getName();
        List<DoctorSearchDTO> results = doctorSearchService.getTopRatedDoctors(uid);
        return ResponseEntity.ok(results);
    }
}
