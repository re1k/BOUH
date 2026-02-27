package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.appointmentDto;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ExecutionException;

/**
 * Repository for Firestore collection "appointments".
 */
@Repository
public class AppointmentRepo {

    private static final ZoneId ZONE = ZoneId.systemDefault();

    private final Firestore firestore;
    private static final String COLLECTION = "appointments";

    public AppointmentRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Returns appointments for the given caregiver with date >= today, ordered by
     * date.
     * Strategy: query Firestore by caregiverId only, then filter by date and sort
     * in memory.
     */
    public List<appointmentDto> findByCaregiverIdAndDateFromToday(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();

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
            dto.setDate(getDateAsYyyyMmDd(doc));
            dto.setTimeSlotId(getString(doc, "timeSlotId"));
            dto.setStartTime(getSlotIndexForDerivation(doc));
            dto.setEndTime(getString(doc, "endTime"));
            dto.setStatus(getStatusAsInt(doc));
            dto.setMeetingLink(getString(doc, "meetingLink"));
            dto.setAmount(doc.getLong("amount"));
            dto.setPaymentIntentId(getString(doc, "paymentIntentId"));
            list.add(dto);
        }

        // Filter: date >= today (date normalized to yyyy-MM-dd or null)
        list.removeIf(d -> {
            String date = d.getDate();
            if (date == null || date.isEmpty())
                return true;
            return date.compareTo(today) < 0;
        });
        // Sort by date ascending (same as orderBy("date"))
        list.sort(Comparator.comparing(appointmentDto::getDate, Comparator.nullsLast(Comparator.naturalOrder())));
        return list;
    }

    /**
     * Returns appointments for the given caregiver with date < today, ordered by
     * date descending (most recent first).
     */
    public List<appointmentDto> findByCaregiverIdAndDateBeforeToday(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();

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
            dto.setDate(getDateAsYyyyMmDd(doc));
            dto.setTimeSlotId(getString(doc, "timeSlotId"));
            dto.setStartTime(getSlotIndexForDerivation(doc));
            dto.setEndTime(getString(doc, "endTime"));
            dto.setStatus(getStatusAsInt(doc));
            dto.setMeetingLink(getString(doc, "meetingLink"));
            dto.setAmount(doc.getLong("amount"));
            dto.setPaymentIntentId(getString(doc, "paymentIntentId"));
            list.add(dto);
        }

        list.removeIf(d -> {
            String date = d.getDate();
            if (date == null || date.isEmpty())
                return true;
            return date.compareTo(today) >= 0;
        });
        list.sort(Comparator.comparing(appointmentDto::getDate, Comparator.nullsLast(Comparator.reverseOrder())));
        return list;
    }

    /**
     * Returns all appointments for the caregiver (no date/status filter). For
     * debugging: GET /api/dev/debug-appointments/{caregiverId}
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
            dto.setDate(getDateAsYyyyMmDd(doc));
            dto.setTimeSlotId(getString(doc, "timeSlotId"));
            dto.setStartTime(getSlotIndexForDerivation(doc));
            dto.setEndTime(getString(doc, "endTime"));
            dto.setStatus(getStatusAsInt(doc));
            dto.setMeetingLink(getString(doc, "meetingLink"));
            dto.setAmount(doc.getLong("amount"));
            dto.setPaymentIntentId(getString(doc, "paymentIntentId"));
            list.add(dto);
        }
        return list;
    }

    /** Read date from document (Timestamp/Date only). Returns yyyy-MM-dd or null. */
    private static String getDateAsYyyyMmDd(QueryDocumentSnapshot doc) {
        Date d = asDate(doc.get("date"));
        if (d == null) return null;
        return d.toInstant().atZone(ZONE).toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
    }

    private static Date asDate(Object v) {
        if (v == null) return null;
        if (v instanceof Date) return (Date) v;
        try {
            Object o = v.getClass().getMethod("toDate").invoke(v);
            return o instanceof Date ? (Date) o : null;
        } catch (Exception e) {
            return null;
        }
    }

    /** Status stored as number in DB: 0 or 1. */
    private static int getStatusAsInt(QueryDocumentSnapshot doc) {
        Object v = doc.get("status");
        if (v instanceof Number)
            return ((Number) v).intValue() == 1 ? 1 : 0;
        if (v != null && "1".equals(v.toString().trim()))
            return 1;
        return 0;
    }

    /** Slot index (0-9) as string for time derivation: from slotIndex field */
    private static String getSlotIndexForDerivation(QueryDocumentSnapshot doc) {
        Object slotIndex = doc.get("slotIndex");
        if (slotIndex != null) {
            return slotIndex.toString();
        }
        return getString(doc, "startTime");
    }

    private static String getString(QueryDocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        return v == null ? null : v.toString();
    }
}
