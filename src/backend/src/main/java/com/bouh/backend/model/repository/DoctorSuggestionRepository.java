package com.bouh.backend.model.repository;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.Collections;

@Repository
public class DoctorSuggestionRepository {
    private final Firestore firestore;

    public DoctorSuggestionRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public boolean hasEmotionExceededThreshold(String caregiverId, String childId, String emotion)
            throws ExecutionException, InterruptedException {

        Date thirtyDaysAgo = Date.from(
                LocalDateTime.now().minusDays(30)
                        .atZone(ZoneId.systemDefault())
                        .toInstant());

        ApiFuture<QuerySnapshot> future = firestore
                .collection("caregivers")
                .document(caregiverId)
                .collection("children")
                .document(childId)
                .collection("drawingAnalysis")
                .whereEqualTo("emotionClass", emotion)
                .whereGreaterThanOrEqualTo("createdAt", thirtyDaysAgo)
                .limit(3) // stop fetching after 3 docs
                .get();

        return future.get().size() == 3;
    }

    public List<Map<String, Object>> findDoctorsByAreaOfKnowledge(String emotion)
            throws ExecutionException, InterruptedException {

        ApiFuture<QuerySnapshot> future = firestore
                .collection("doctors")
                .whereEqualTo("areaOfKnowledge", emotion)
                .whereEqualTo("registrationStatus", "APPROVED")
                .whereEqualTo("isActivated", true)
                .whereGreaterThanOrEqualTo("averageRating", 4)
                .get();

        List<Map<String, Object>> doctors = new ArrayList<>();
        for (QueryDocumentSnapshot doc : future.get().getDocuments()) {
            Map<String, Object> data = new HashMap<>(doc.getData());
            data.put("id", doc.getId());
            doctors.add(data);
        }

        Collections.shuffle(doctors);
        return doctors.size() > 3 ? doctors.subList(0, 3) : doctors;
    }
}
