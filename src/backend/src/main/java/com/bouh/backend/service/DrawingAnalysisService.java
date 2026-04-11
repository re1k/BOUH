package com.bouh.backend.service;

import com.bouh.backend.model.repository.DrawingRepo;
import com.bouh.backend.model.Dto.DoctorSuggestionDTO;
import com.bouh.backend.model.Dto.DrawingAnalysis.DrawingAnalysisRequestDto;
import com.bouh.backend.model.Dto.DrawingAnalysis.DrawingAnalysisResponseDto;
import com.bouh.backend.model.Dto.DrawingAnalysis.HistoryResponseDto;
import com.bouh.backend.service.classification.ClassificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

/**
 * DrawingAnalysisService
 *
 * Owns the full pipeline:
 *
 *   [1] ClassificationService  → emotion string (hard failure — stops pipeline)
 *   [2] GeminiService          ─┐ parallel, each degrades independently
 *       DoctorSuggestionService─┘
 *   [3] DrawingRepo.save()     → persists everything, returns drawingId
 */
@Slf4j
@Service
public class DrawingAnalysisService {

    private final ClassificationService classificationService;
    private final GeminiService geminiService;
    private final DoctorSuggestionService doctorSuggestionService;
    private final DrawingRepo drawingRepo;

    public DrawingAnalysisService(ClassificationService classificationService,
                                  GeminiService geminiService,
                                  DoctorSuggestionService doctorSuggestionService,
                                  DrawingRepo drawingRepo) {
        this.classificationService = classificationService;
        this.geminiService = geminiService;
        this.doctorSuggestionService = doctorSuggestionService;
        this.drawingRepo = drawingRepo;
    }

    public DrawingAnalysisResponseDto analyze(String caregiverId,
                                              DrawingAnalysisRequestDto request) {

        // Step 1 — classify. Any exception here stops everything.
        String emotion = classificationService.classify(request.getImagePath());
        log.info("[DrawingAnalysisService] Emotion detected: {}", emotion);

        // Step 2 — Gemini + doctors in parallel
        CompletableFuture<String> interpretationFuture =
                CompletableFuture.supplyAsync(() -> {
                    try {
                        return geminiService.analyzeFeeling(emotion);
                    } catch (Exception e) {
                        log.error("[DrawingAnalysisService] Gemini failed: {}", e.getMessage());
                        return ""; // save record without interpretation
                    }
                });

        CompletableFuture<List<DoctorSuggestionDTO>> doctorsFuture =
                CompletableFuture.supplyAsync(() -> {
                    try {
                        List<DoctorSuggestionDTO> result = doctorSuggestionService
                                .suggestDoctors(caregiverId, request.getChildId(), emotion);
                        log.info("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[DrawingAnalysisService] Doctors suggested: {}", result.size()); 
                        return result;
                    } catch (Exception e) {
                        log.error("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[DrawingAnalysisService] Doctor suggestion failed: {}", e.getMessage());
                        return List.of();
                    }
                });

        String interpretation;
        List<DoctorSuggestionDTO> doctors;
        try {
            CompletableFuture.allOf(interpretationFuture, doctorsFuture).get();
            interpretation = interpretationFuture.get();
            doctors = doctorsFuture.get();
        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("[DrawingAnalysisService] Pipeline interrupted", e);
        }

        // Step 3
        String drawingId = drawingRepo.save(
                caregiverId,
                request.getChildId(),
                request.getImageURL(),
                emotion,
                interpretation,
                doctors  // full list, embedded in the Firestore document
        );

        log.info("[DrawingAnalysisService] Saved → drawingId: {}", drawingId);

        return new DrawingAnalysisResponseDto(drawingId, emotion, interpretation, doctors);
    }

    public HistoryResponseDto getHistory(String caregiverId,
                                          String childId,
                                          String cursor,
                                          int limit) {
        return drawingRepo.findHistory(caregiverId, childId, cursor, limit);
    }
}