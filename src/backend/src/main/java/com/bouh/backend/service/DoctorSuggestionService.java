package com.bouh.backend.service;

import com.bouh.backend.model.repository.DoctorSuggestionRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class DoctorSuggestionService {
    private final DoctorSuggestionRepository doctorSuggestionRepository;

    public DoctorSuggestionService(DoctorSuggestionRepository doctorSuggestionRepository) {
        this.doctorSuggestionRepository = doctorSuggestionRepository;
    }

    public List<String> suggestDoctors(String caregiverId, String childId, String emotionClass)
            throws ExecutionException, InterruptedException {

        boolean shouldSuggest = !emotionClass.equalsIgnoreCase("سعادة") && doctorSuggestionRepository
                .hasEmotionExceededThreshold(caregiverId, childId, emotionClass);

        if (!shouldSuggest) {
            return new ArrayList<>();
        }

        // Fetch up to 3 matching doctors
        List<Map<String, Object>> doctorsData = doctorSuggestionRepository.findDoctorsByAreaOfKnowledge(emotionClass);

        // return only IDs
        return doctorsData.stream()
                .map(doc -> (String) doc.get("id"))
                .collect(Collectors.toList());
    }

}
