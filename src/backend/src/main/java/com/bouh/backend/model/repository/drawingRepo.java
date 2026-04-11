package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.DoctorSuggestionDTO;
import com.bouh.backend.model.Dto.DrawingAnalysis.drawingDto;
import com.bouh.backend.model.Dto.DrawingAnalysis.HistoryResponseDto;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * DrawingRepo
 *
 * Firestore path:
 *   caregivers/{caregiverId}/children/{childId}/drawingAnalysis/{drawingId}
 *
 * Document structure:
 * {
 *   imageURL:                "drawings/abc.jpg"
 *   emotionClass:            "حزن"
 *   emotionalInterpretation: "يبدو أن طفلك..."
 *   createdAt:               Timestamp
 *   doctors: [
 *     { id: "d1", name: "د.علي", profilePhotoURL: "........" },
 *     { id: "d2", name: "د.موسى", profilePhotoURL: null }
 *   ]
 * }
 *
 */
@Slf4j
@Repository
public class DrawingRepo {

    private final Firestore firestore;

    public DrawingRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Saves a completed drawing analysis to Firestore.
     *
     * Doctors are serialized as a list of maps so Firestore stores them
     * as an array of objects inside the document, not as a separate collection.
     *
     * @param caregiverId           caregiver who owns the child
     * @param childId               child the drawing belongs to
     * @param imageURL              path
     * @param emotionClass          emotion label from the classifier
     * @param emotionalInterpretation Gemini paragraph (empty string if Gemini failed)
     * @param doctors               list of suggested doctors (empty list if threshold not met)
     * @return auto-generated Firestore document ID
     */
    public String save(String caregiverId,
                       String childId,
                       String imageURL,
                       String emotionClass,
                       String emotionalInterpretation,
                       List<DoctorSuggestionDTO> doctors) {

        // Convert each DoctorSuggestionDTO into a plain Map so Firestore
        // can serialize it as a nested object inside the document array
        List<Map<String, Object>> doctorMaps = new ArrayList<>();
        for (DoctorSuggestionDTO doctor : doctors) {
            Map<String, Object> doctorMap = new HashMap<>();
            doctorMap.put("id", doctor.getId());
            doctorMap.put("name", doctor.getName());
            // profilePhotoURL may be null — Firestore stores null fields correctly
            doctorMap.put("profilePhotoURL",
                    doctor.getProfilePhotoURL() != null ? doctor.getProfilePhotoURL() : "");
            doctorMaps.add(doctorMap);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("imageURL", imageURL); 
        data.put("emotionClass", emotionClass);
        data.put("emotionalInterpretation", emotionalInterpretation);
        data.put("doctors", doctorMaps); // embedded array of maps
        data.put("createdAt", Timestamp.now());

        try {
            DocumentReference ref = firestore
                    .collection("caregivers")
                    .document(caregiverId)
                    .collection("children")
                    .document(childId)
                    .collection("drawingAnalysis")
                    .add(data)
                    .get();

            log.info("[DrawingRepo] Saved drawing analysis → id: {}, doctors embedded: {}",
                    ref.getId(), doctors.size());

            return ref.getId();

        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("[DrawingRepo] Failed to save drawing analysis", e);
        }
    }

    /**
     * Returns a cursor-based page of drawing analysis records, newest first.
     *
     * How pagination works:
     *   - First page:  cursor = null → starts from the most recent record
     *   - Next pages:  cursor = drawingId of the last record from the previous page
     *   - Last page:   nextCursor in the response will be null → client stops
     *
     * We fetch (limit + 1) records and check if the extra one exists.
     * If yes → there is a next page, slice to limit, set nextCursor.
     * If no  → this is the last page, return all, set nextCursor = null.
     *
     * @param caregiverId caregiver who owns the child
     * @param childId     child whose history is being fetched
     * @param cursor      drawingId of the last record from the previous page, null for first page
     * @param limit       max records per page
     * @return HistoryResponseDto with records list and nextCursor
     */
    public HistoryResponseDto findHistory(String caregiverId,
                                           String childId,
                                           String cursor,
                                           int limit) {
        try {
            // Base collection reference for the child's drawing analysis nothing fetched yet
            CollectionReference collection = firestore
                    .collection("caregivers")
                    .document(caregiverId)
                    .collection("children")
                    .document(childId)
                    .collection("drawingAnalysis");

            // Fetch one extra to detect whether another page exists
            Query query = collection
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .limit(limit + 1); //limit + 1 to check for next page existence without an extra query

            // If a cursor is provided, resolve it and resume after that document
            if (cursor != null && !cursor.isBlank()) {
                DocumentSnapshot cursorSnapshot = collection
                        .document(cursor)
                        .get()
                        .get();

                if (cursorSnapshot.exists()) { //this what makes the pagination works
                    query = query.startAfter(cursorSnapshot);
                } else {
                    // Cursor document was deleted — fall back to first page
                    log.warn("[DrawingRepo] Cursor document {} not found, returning from start",
                            cursor);
                }
            }

            List<QueryDocumentSnapshot> docs = query.get().get().getDocuments();

            boolean hasNextPage = docs.size() > limit;
            List<QueryDocumentSnapshot> page = hasNextPage
                    ? docs.subList(0, limit)
                    : docs;

            List<drawingDto> records = new ArrayList<>();

            for (QueryDocumentSnapshot doc : page) {
                drawingDto dto = new drawingDto();
                dto.setDrawingId(doc.getId());
                dto.setImageURL(doc.getString("imageURL"));
                dto.setEmotionClass(doc.getString("emotionClass"));
                dto.setEmotionalInterpretation(
                        doc.getString("emotionalInterpretation"));

                // Convert Firestore Timestamp → java.time.Instant
                Timestamp ts = doc.getTimestamp("createdAt");
                if (ts != null) {
                    dto.setCreatedAt(ts.toDate().toInstant());
                }

                // Read the embedded doctors array back into DoctorSuggestionDTO objects.
                // Firestore stores each doctor as a Map<String, Object>.
                List<DoctorSuggestionDTO> doctors = new ArrayList<>();
                List<?> rawDoctors = (List<?>) doc.get("doctors"); 
                if (rawDoctors != null) {
                    for (Object raw : rawDoctors) {
                        if (raw instanceof Map<?, ?> map) {
                            DoctorSuggestionDTO doctor = new DoctorSuggestionDTO(
                                    (String) map.get("id"),
                                    (String) map.get("name"),
                                    emptyToNull((String) map.get("profilePhotoURL"))
                            );
                            doctors.add(doctor);
                        }
                    }
                }
                dto.setDoctors(doctors);

                records.add(dto);
            }

            String nextCursor = hasNextPage
                    ? page.get(page.size() - 1).getId()
                    : null;

            log.info("[DrawingRepo] History page → {} record(s), nextCursor: {}",
                    records.size(), nextCursor);

            return new HistoryResponseDto(records, nextCursor);

        } catch (InterruptedException | ExecutionException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("[DrawingRepo] Failed to fetch drawing history", e);
        }
    }

    /** Converts empty string back to null for profilePhotoURL. */
    private String emptyToNull(String value) {
        return (value == null || value.isBlank()) ? null : value;
    }
}