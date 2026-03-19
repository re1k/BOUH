package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.DoctorSuggestionDTO;
import com.bouh.backend.service.DoctorSuggestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/test/doctor-suggestions")
public class DoctorSuggestionController {
    private final DoctorSuggestionService doctorSuggestionService;

    public DoctorSuggestionController(DoctorSuggestionService doctorSuggestionService) {
        this.doctorSuggestionService = doctorSuggestionService;
    }

    @GetMapping("/{caregiverId}/{childId}/{emotionClass}")
    public ResponseEntity<List<DoctorSuggestionDTO>> getSuggestions(
            @PathVariable String caregiverId,
            @PathVariable String childId,
            @PathVariable String emotionClass) throws ExecutionException, InterruptedException {

        List<DoctorSuggestionDTO> suggestions = doctorSuggestionService.suggestDoctors(caregiverId, childId,
                emotionClass);

        return ResponseEntity.ok(suggestions);
    }
}
