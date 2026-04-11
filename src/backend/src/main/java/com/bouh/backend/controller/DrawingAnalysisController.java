package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.DrawingAnalysis.DrawingAnalysisRequestDto;
import com.bouh.backend.model.Dto.DrawingAnalysis.DrawingAnalysisResponseDto;
import com.bouh.backend.model.Dto.DrawingAnalysis.HistoryResponseDto;
import com.bouh.backend.service.DrawingAnalysisService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * DrawingAnalysisController
 *
 * Thin HTTP layer — zero business logic lives here.
 *
 * Endpoints:
 *   POST /api/drawingAnalysis/analyze          → run full analysis pipeline
 *   GET  /api/drawingAnalysis/history/{childId} → paginated history
 */
@RestController
@RequestMapping("/api/drawingAnalysis")
public class DrawingAnalysisController {

    private final DrawingAnalysisService drawingAnalysisService;

    public DrawingAnalysisController(DrawingAnalysisService drawingAnalysisService) {
        this.drawingAnalysisService = drawingAnalysisService;
    }
    
    @PostMapping("/analyze")
    public ResponseEntity<DrawingAnalysisResponseDto> analyze(
            @RequestBody DrawingAnalysisRequestDto request,
            Authentication authentication) {

        return ResponseEntity.ok(
            drawingAnalysisService.analyze(authentication.getName(), request)
        );
    }

    @GetMapping("/history/{childId}")
    public ResponseEntity<HistoryResponseDto> getHistory(
            @PathVariable String childId,
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int limit,
            Authentication authentication) {

        return ResponseEntity.ok(
            drawingAnalysisService.getHistory(
                authentication.getName(), childId, cursor, limit)
        );
    }
}