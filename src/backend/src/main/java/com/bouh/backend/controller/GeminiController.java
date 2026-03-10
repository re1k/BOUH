package com.bouh.backend.controller;

import com.bouh.backend.service.GeminiService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// Remove this (after testing)
@RestController
@RequestMapping("/api/gemini")
public class GeminiController {

    private final GeminiService geminiService;

    public GeminiController(GeminiService geminiService) {
        this.geminiService = geminiService;
    }

    @GetMapping(value = "/analyze", produces = "application/json; charset=UTF-8")
    public ResponseEntity<Map<String, String>> analyze(@RequestParam String emotion) {
        try {
            String result = geminiService.analyzeFeeling(emotion);
            return ResponseEntity.ok(Map.of("emotion", emotion, "analysis", result));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
