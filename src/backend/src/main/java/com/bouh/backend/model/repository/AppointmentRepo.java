package com.bouh.backend.model.repository;

import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.DocumentSnapshot;
import java.util.HashMap;
import java.util.Map;
/**
 * Repository for Firestore collection "appointments".
 */
@Repository
public class AppointmentRepo {

    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");

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
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = mapDocToDto(doc);
            list.add(dto);
        }

        // Keep only appointments that start today or later. Sort by start time, soonest
        // first.
        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();
        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).isBefore(todayStart);
        });
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.naturalOrder())));
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
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = mapDocToDto(doc);
            list.add(dto);
        }

        // Keep only appointments that start before today. Sort by start time, newest
        // first.
        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();
        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).compareTo(todayStart) >= 0;
        });
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.reverseOrder())));
        return list;
    }


    public List<appointmentDto> findByDoctorIdAndDateFromToday(String doctorId)
            throws ExecutionException, InterruptedException {
        if (doctorId == null || doctorId.isBlank()) {
            return new ArrayList<>();
        }
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("doctorId", doctorId)
                .get()
                .get();
        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = mapDocToDto(doc);
            list.add(dto);
        }
        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();
        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).isBefore(todayStart);
        });
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.naturalOrder())));
        return list;
    }


    public List<appointmentDto> findByDoctorIdAndDateBeforeToday(String doctorId)
            throws ExecutionException, InterruptedException {
        if (doctorId == null || doctorId.isBlank()) {
            return new ArrayList<>();
        }
        QuerySnapshot snapshot = firestore.collection("appointments")
                .whereEqualTo("doctorId", doctorId)
                .get()
                .get();
        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            appointmentDto dto = mapDocToDto(doc);
            list.add(dto);
        }
        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();
        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).compareTo(todayStart) >= 0;
        });
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.reverseOrder())));
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
            list.add(mapDocToDto(doc));
        }
        return list;
    }

    // Find a single appointment by its paymentIntentId so we can link refunds back to appointments.
    public appointmentDto findByPaymentIntentId(String paymentIntentId) {
        if (paymentIntentId == null || paymentIntentId.isBlank()) {
            return null;
        }
        try {
            QuerySnapshot snapshot = firestore.collection("appointments")
                    .whereEqualTo("paymentIntentId", paymentIntentId)
                    .limit(1)
                    .get()
                    .get();
            if (snapshot.isEmpty()) {
                return null;
            }
            QueryDocumentSnapshot doc = snapshot.getDocuments().get(0);
            return mapDocToDto(doc);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Interrupted while fetching appointment by paymentIntentId", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("Failed to fetch appointment by paymentIntentId", e);
        }
    }

    // Copy one Firestore document into an appointmentDto. startDateTime is built
    // from date + slot.
    private appointmentDto mapDocToDto(DocumentSnapshot doc) {
        appointmentDto dto = new appointmentDto();
        dto.setAppointmentId(doc.getId());
        dto.setCaregiverId(getString(doc, "caregiverId"));
        dto.setChildId(getString(doc, "childId"));
        dto.setDoctorId(getString(doc, "doctorId"));
        dto.setTimeSlotId(getString(doc, "timeSlotId"));
        dto.setStartDateTime(getStartDateTime(doc));// Important: this combines the date and slot index into one timestamp for easier handling in Java. It expects the date field to be a Firestore Timestamp or Date.REMAZ 
        dto.setEndTime(getString(doc, "endTime"));
        dto.setStatus(getStatusAsInt(doc));
        dto.setMeetingLink(getString(doc, "meetingLink"));
        dto.setAmount(doc.getLong("amount"));
        dto.setPaymentIntentId(getString(doc, "paymentIntentId"));
        return dto;
    }

    // Combine the document's date and slot index into one timestamp (start of the
    // appointment).
    private Timestamp buildStartDateTime(DocumentSnapshot doc) {
        String dateStr = getDateAsYyyyMmDd(doc);
        if (dateStr == null || dateStr.isEmpty())
            return null;
        int slotIndex = TimeSlotConfig.parseSlotIndex(getSlotIndexForDerivation(doc));
        if (slotIndex < 0 || slotIndex >= TimeSlotConfig.SLOT_COUNT)
            return null;
        LocalDate date = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
        LocalDateTime ldt = date.atTime(TimeSlotConfig.slotStart(slotIndex));
        return Timestamp.of(Date.from(ldt.atZone(ZONE).toInstant()));
    }

    /**
     * Read date from document (Timestamp/Date only). Returns yyyy-MM-dd or null.
     */
    private static String getDateAsYyyyMmDd(DocumentSnapshot doc) {
        Date d = asDate(doc.get("date"));
        if (d == null)
            return null;
        return d.toInstant().atZone(ZONE).toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
    }

    private static Date asDate(Object v) {
        if (v == null)
            return null;
        if (v instanceof Date)
            return (Date) v;
        try {
            Object o = v.getClass().getMethod("toDate").invoke(v);
            return o instanceof Date ? (Date) o : null;
        } catch (Exception e) {
            return null;
        }
    }

    /** Status stored as number in DB: 0 or 1. */
    private static int getStatusAsInt(DocumentSnapshot doc) {
        Object v = doc.get("status");
        if (v instanceof Number)
            return ((Number) v).intValue() == 1 ? 1 : 0;
        if (v != null && "1".equals(v.toString().trim()))
            return 1;
        return 0;
    }

    /** Slot index (0-9) as string for time derivation: from slotIndex field */
    private static String getSlotIndexForDerivation(DocumentSnapshot doc) {
        Object slotIndex = doc.get("slotIndex");
        if (slotIndex != null) {
            return slotIndex.toString();
        }
        return getString(doc, "startTime");
    }

    private static String getString(DocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        return v == null ? null : v.toString();
    }
    public boolean caregiverHasConflict(String caregiverId, String date, int slotIndex)
        throws ExecutionException, InterruptedException {
    List<appointmentDto> list = findByCaregiverIdAndDateFromToday(caregiverId);

    for (appointmentDto dto : list) {
        Timestamp start = dto.getStartDateTime();
        if (start == null) continue;

        ZonedDateTime zdt = ZonedDateTime.ofInstant(
                Instant.ofEpochSecond(start.getSeconds(), start.getNanos()),
                ZONE
        );

        String existingDate = zdt.toLocalDate().toString();
        int existingSlot = TimeSlotConfig.getSlotIndexForStartTime(zdt.toLocalTime());

        if (date.equals(existingDate) && slotIndex == existingSlot) {
            return true;
        }
    }
    return false;
}
public appointmentDto create(appointmentDto dto, String date, int slotIndex)
        throws ExecutionException, InterruptedException {

    DocumentReference ref = firestore.collection(COLLECTION).document();

    LocalDate localDate = LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE);
    LocalDateTime startLdt = localDate.atTime(TimeSlotConfig.slotStart(slotIndex));
    Timestamp startTimestamp = Timestamp.of(Date.from(startLdt.atZone(ZONE).toInstant()));

    Map<String, Object> data = new HashMap<>();
    data.put("caregiverId", dto.getCaregiverId());
    data.put("doctorId", dto.getDoctorId());
    data.put("childId", dto.getChildId());

  
    data.put("slotIndex", slotIndex);

    // مهم:  getDateAsYyyyMmDd يتوقع Timestamp
    data.put("date", Date.from(localDate.atStartOfDay(ZONE).toInstant()));

 
    data.put("startDateTime", startTimestamp);

    data.put("endTime", dto.getEndTime());
    data.put("meetingLink", dto.getMeetingLink());
    data.put("amount", dto.getAmount());
    data.put("status", dto.getStatus() == null ? 0 : dto.getStatus());
    data.put("paymentIntentId", dto.getPaymentIntentId());

    ref.set(data).get();

    dto.setAppointmentId(ref.getId());
    dto.setTimeSlotId(String.valueOf(slotIndex));
    dto.setStartDateTime(startTimestamp);

    return dto;
}
private Timestamp getStartDateTime(DocumentSnapshot doc) {
    Object raw = doc.get("startDateTime");

    if (raw instanceof Timestamp) {
        return (Timestamp) raw;
    }

    return buildStartDateTime(doc);
}
public appointmentDto findById(String appointmentId)
        throws ExecutionException, InterruptedException {
    if (appointmentId == null || appointmentId.isBlank()) {
        return null;
    }

    DocumentSnapshot doc = firestore.collection(COLLECTION)
            .document(appointmentId)
            .get()
            .get();

    if (!doc.exists()) {
        return null;
    }

    return mapDocToDto(doc);
}

public void deleteById(String appointmentId)
        throws ExecutionException, InterruptedException {
    if (appointmentId == null || appointmentId.isBlank()) {
        throw new IllegalArgumentException("appointmentId is required");
    }

    firestore.collection(COLLECTION)
            .document(appointmentId)
            .delete()
            .get();
}

}
