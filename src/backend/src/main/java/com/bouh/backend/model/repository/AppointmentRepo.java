package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.appointmentDto;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ExecutionException;

/**
 * Repository for Firestore collection "appointments".
 */
@Repository
public class appointmentRepo {

    private final Firestore firestore;

    public appointmentRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Returns appointments for the given caregiver with date >= today, ordered by date.
     * Strategy: query Firestore by caregiverId only, then filter by date and sort in memory.
     */
    public List<appointmentDto> findByCaregiverIdAndDateFromToday(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }
        String today = ZonedDateTime.now(ZoneId.of("Asia/Riyadh")).toLocalDate().toString(); // yyyy-MM-dd

        
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = new appointmentDto();
            dto.setAppointmentId(doc.getId());
            dto.setCaregiverId(getString(doc, "caregiverId"));
            dto.setChildId(getString(doc, "childId"));
            dto.setDoctorId(getString(doc, "doctorId"));
            dto.setDate(normalizeDate(getString(doc, "date")));
            dto.setTimeSlotId(getString(doc, "timeSlotId"));
            dto.setStatus(getString(doc, "status"));
            dto.setMeetingLink(getString(doc, "meetingLink"));
            dto.setAmount(doc.getLong("amount"));
            list.add(dto);
        }

        // Filter: date >= today (date normalized to yyyy-MM-dd or null)
        list.removeIf(d -> {
            String date = d.getDate();
            if (date == null || date.isEmpty()) return true;
            return date.compareTo(today) < 0;
        });
        // Sort by date ascending (same as orderBy("date"))
        list.sort(Comparator.comparing(appointmentDto::getDate, Comparator.nullsLast(Comparator.naturalOrder())));
        return list;
    }

    /**
     * Returns all appointments for the caregiver (no date/status filter). For debugging: GET /api/dev/debug-appointments/{caregiverId}
     */
    public List<appointmentDto> findAllByCaregiverId(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();
        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = new appointmentDto();
            dto.setAppointmentId(doc.getId());
            dto.setCaregiverId(getString(doc, "caregiverId"));
            dto.setChildId(getString(doc, "childId"));
            dto.setDoctorId(getString(doc, "doctorId"));
            dto.setDate(normalizeDate(getString(doc, "date")));
            dto.setTimeSlotId(getString(doc, "timeSlotId"));
            dto.setStatus(getString(doc, "status"));
            dto.setMeetingLink(getString(doc, "meetingLink"));
            dto.setAmount(doc.getLong("amount"));
            list.add(dto);
        }
        return list;
    }

    private static String getString(QueryDocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        return v == null ? null : v.toString();
    }

    /** Normalize date to yyyy-MM-dd: if ISO (e.g. 2026-03-10T21:37:59.504Z), take first 10 chars; else trim. */
    private static String normalizeDate(String date) {
        if (date == null) return null;
        date = date.trim();
        if (date.isEmpty()) return null;
        if (date.length() >= 10 && date.charAt(4) == '-' && date.charAt(7) == '-') {
            return date.substring(0, 10);
        }
        return date;
    }
}
