package com.bouh.backend.model.Dto.DrawingAnalysis;

import lombok.Data;

/**
 * Request body for POST /api/drawingAnalysis/analyze
 */
@Data
public class DrawingAnalysisRequestDto {
    private String imagePath;
    private String imageURL;
    private String childId;
}