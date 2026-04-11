package com.bouh.backend.model.Dto.DrawingAnalysis;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.Data;
import java.time.Instant;
import java.util.List;
import com.bouh.backend.model.Dto.DoctorSuggestionDTO;

@Data //setters,getters and constructors
public class drawingDto {
    @DocumentId
    private String drawingId;

    private String imageURL;
    private String emotionClass;
    private String emotionalInterpretation;
    private Instant createdAt;
    private List<DoctorSuggestionDTO> doctors;
}
