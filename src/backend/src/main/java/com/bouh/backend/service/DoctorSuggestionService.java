package com.bouh.backend.service;

import com.bouh.backend.model.Dto.DoctorSuggestionDTO;
import com.bouh.backend.model.repository.DoctorSuggestionRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class DoctorSuggestionService {
    private final DoctorSuggestionRepository doctorSuggestionRepository;

    public DoctorSuggestionService(DoctorSuggestionRepository doctorSuggestionRepository) {
        this.doctorSuggestionRepository = doctorSuggestionRepository;
    }

    public List<DoctorSuggestionDTO> suggestDoctors(String caregiverId, String childId, String emotionClass)
            throws ExecutionException, InterruptedException {

        boolean shouldSuggest = doctorSuggestionRepository
                .hasEmotionExceededThreshold(caregiverId, childId, emotionClass);

        if (!shouldSuggest) {
            return new ArrayList<>();
        }

        // Fetch up to 3 matching doctors
        List<Map<String, Object>> doctorsData = doctorSuggestionRepository.findDoctorsByAreaOfKnowledge(emotionClass);

        // Map to DTO
        List<DoctorSuggestionDTO> suggestions = new ArrayList<>();
        for (Map<String, Object> doc : doctorsData) {
            DoctorSuggestionDTO dto = new DoctorSuggestionDTO(
                    (String) doc.get("id"),
                    (String) doc.get("name"),
                    (String) doc.get("profilePhotoURL"));
            suggestions.add(dto);
        }

        return suggestions;
    }
}
