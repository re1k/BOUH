package com.bouh.backend.controller;

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
            @RequestParam String name) throws ExecutionException, InterruptedException {

        List<DoctorSearchDTO> results = doctorSearchService.searchByName(name);
        return ResponseEntity.ok(results);
    }

    @GetMapping("/top-rated")
    public ResponseEntity<List<DoctorSearchDTO>> getTopRatedDoctors() throws ExecutionException, InterruptedException {
        List<DoctorSearchDTO> results = doctorSearchService.getTopRatedDoctors();
        return ResponseEntity.ok(results);
    }
}
