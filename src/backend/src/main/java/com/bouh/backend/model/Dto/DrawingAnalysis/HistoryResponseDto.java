package com.bouh.backend.model.Dto.DrawingAnalysis;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class HistoryResponseDto {
    private List<drawingDto> records;  // the 10 drawing cards to show
    private String nextCursor;         // the ID to send on the next request, or null
}