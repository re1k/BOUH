package com.bouh.backend.model.Dto.DrawingAnalysis;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;

import com.bouh.backend.model.Dto.DoctorSuggestionDTO;

/**
 * Response body for POST /api/drawingAnalysis/analyze
 * 
 * Not used for history — history uses DrawingDto inside HistoryResponseDto.
 */
@Data
@AllArgsConstructor
public class DrawingAnalysisResponseDto {

    private String drawingId;

    /** Emotion label from the classifier e.g. "حزن", "تفاؤل" */
    private String emotion;

    /**
     * Gemini-generated caregiver guidance.
     */
    private String emotionalInterpretation;

    /**
     * Up to 3 suggested doctors.
     * Empty list when threshold not met — never null.
     */
    private List<DoctorSuggestionDTO> doctors;
}