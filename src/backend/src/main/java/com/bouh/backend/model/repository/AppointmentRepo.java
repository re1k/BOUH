package com.bouh.backend.model.repository;

import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * Repository for Firestore collection "appointments".
 */
@Repository
public class AppointmentRepo {

    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");
    private static final String COLLECTION = "appointments";
    private static final String SLOT_LOCKS_COLLECTION = "appointment_slot_locks";

    private final Firestore firestore;

    public AppointmentRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    private String buildSlotLockId(String doctorId, String date, int slotIndex) {
        return doctorId + "_" + date + "_" + slotIndex;
    }

    /**
     * Returns appointments for the given caregiver with date >= today, ordered by
     * start time ascending.
     */
    public List<appointmentDto> findUpcomingByCaregiverId(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }

        QuerySnapshot snapshot = firestore.collection(COLLECTION)
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            list.add(mapDocToDto(doc));
        }

        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();

        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).isBefore(todayStart);
        });

        list.sort(Comparator.comparing(
                appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.naturalOrder())));

        return list;
    }

    /**
     * Returns appointments for the given caregiver with date < today, ordered by
     * start time descending.
     */
    public List<appointmentDto> findPastByCaregiverId(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }

        QuerySnapshot snapshot = firestore.collection(COLLECTION)
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            list.add(mapDocToDto(doc));
        }

        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();

        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).compareTo(todayStart) >= 0;
        });

        list.sort(Comparator.comparing(
                appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.reverseOrder())));

        return list;
    }

    /**
     * Returns appointments for the given doctor with date >= today, ordered by
     * start time ascending.
     */
    public List<appointmentDto> findUpcomingByDoctorId(String doctorId)
            throws ExecutionException, InterruptedException {
        if (doctorId == null || doctorId.isBlank()) {
            return new ArrayList<>();
        }

        QuerySnapshot snapshot = firestore.collection(COLLECTION)
                .whereEqualTo("doctorId", doctorId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            list.add(mapDocToDto(doc));
        }

        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();

        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).isBefore(todayStart);
        });

        list.sort(Comparator.comparing(
                appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.naturalOrder())));

        return list;
    }

    /**
     * Returns appointments for the given doctor with date < today, ordered by start
     * time descending.
     */
    public List<appointmentDto> findPastByDoctorId(String doctorId)
            throws ExecutionException, InterruptedException {
        if (doctorId == null || doctorId.isBlank()) {
            return new ArrayList<>();
        }

        QuerySnapshot snapshot = firestore.collection(COLLECTION)
                .whereEqualTo("doctorId", doctorId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            list.add(mapDocToDto(doc));
        }

        Instant todayStart = ZonedDateTime.now(ZONE).toLocalDate().atStartOfDay(ZONE).toInstant();

        list.removeIf(d -> {
            Timestamp t = d.getStartDateTime();
            return t == null || Instant.ofEpochSecond(t.getSeconds(), t.getNanos()).compareTo(todayStart) >= 0;
        });

        list.sort(Comparator.comparing(
                appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.reverseOrder())));

        return list;
    }

    /**
     * Returns all appointments for the caregiver (no date filter).
     */
    public List<appointmentDto> findAllByCaregiverId(String caregiverId)
            throws ExecutionException, InterruptedException {
        if (caregiverId == null || caregiverId.isBlank()) {
            return new ArrayList<>();
        }

        QuerySnapshot snapshot = firestore.collection(COLLECTION)
                .whereEqualTo("caregiverId", caregiverId)
                .get()
                .get();

        List<appointmentDto> list = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            list.add(mapDocToDto(doc));
        }

        return list;
    }

    /**
     * Find one appointment by paymentIntentId.
     */
    public appointmentDto findByPaymentIntentId(String paymentIntentId) {
        if (paymentIntentId == null || paymentIntentId.isBlank()) {
            return null;
        }

        try {
            QuerySnapshot snapshot = firestore.collection(COLLECTION)
                    .whereEqualTo("paymentIntentId", paymentIntentId)
                    .limit(1)
                    .get()
                    .get();

            if (snapshot.isEmpty()) {
                return null;
            }

            return mapDocToDto(snapshot.getDocuments().get(0));

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Interrupted while fetching appointment by paymentIntentId", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("Failed to fetch appointment by paymentIntentId", e);
        }
    }

    /**
     * Create appointment atomically with slot lock to prevent double booking.
     */
    public appointmentDto createAtomically(appointmentDto dto, String date, int slotIndex)
            throws ExecutionException, InterruptedException {

        if (dto == null) {
            throw new IllegalArgumentException("Appointment data is required");
        }
        if (dto.getDoctorId() == null || dto.getDoctorId().isBlank()) {
            throw new IllegalArgumentException("doctorId is required");
        }
        if (dto.getCaregiverId() == null || dto.getCaregiverId().isBlank()) {
            throw new IllegalArgumentException("caregiverId is required");
        }
        if (date == null || date.isBlank()) {
            throw new IllegalArgumentException("date is required");
        }
        if (slotIndex < 0 || slotIndex >= TimeSlotConfig.SLOT_COUNT) {
            throw new IllegalArgumentException("Invalid slotIndex");
        }



        LocalDate localDate = LocalDate.parse(date, DateTimeFormatter.ISO_LOCAL_DATE);
        LocalDateTime startLdt = localDate.atTime(TimeSlotConfig.slotStart(slotIndex));
        Timestamp startTimestamp = Timestamp.of(Date.from(startLdt.atZone(ZONE).toInstant()));

        String lockId = buildSlotLockId(dto.getDoctorId(), date, slotIndex);

        DocumentReference lockRef = firestore.collection(SLOT_LOCKS_COLLECTION).document(lockId);
        DocumentReference appointmentRef = firestore.collection(COLLECTION).document();

        ApiFuture<appointmentDto> future = firestore.runTransaction(transaction -> {
            // 1) Check slot lock
            DocumentSnapshot lockSnap = transaction.get(lockRef).get();
            if (lockSnap.exists()) {
                throw new IllegalStateException("تم حجز هذا الموعد مسبقًا");
            }

            // 2) Check caregiver conflict atomically
            Date dateAtStartOfDay = Date.from(localDate.atStartOfDay(ZONE).toInstant());

            Query caregiverConflictQuery = firestore.collection(COLLECTION)
                    .whereEqualTo("caregiverId", dto.getCaregiverId())
                    .whereEqualTo("date", dateAtStartOfDay)
                    .whereEqualTo("slotIndex", slotIndex)
                    .limit(1);

            QuerySnapshot caregiverConflictSnapshot = transaction.get(caregiverConflictQuery).get();
            if (!caregiverConflictSnapshot.isEmpty()) {
                throw new IllegalStateException("يوجد لديك موعد آخر في نفس التاريخ والوقت");
            }

            // 3) Create lock document
            Map<String, Object> lockData = new HashMap<>();
            lockData.put("doctorId", dto.getDoctorId());
            lockData.put("caregiverId", dto.getCaregiverId());
            lockData.put("date", dateAtStartOfDay);
            lockData.put("slotIndex", slotIndex);
            lockData.put("appointmentId", appointmentRef.getId());
            lockData.put("createdAt", FieldValue.serverTimestamp());

            transaction.set(lockRef, lockData);

            // 4) Create appointment document
            Map<String, Object> data = new HashMap<>();
            data.put("caregiverId", dto.getCaregiverId());
            data.put("doctorId", dto.getDoctorId());
            data.put("childId", dto.getChildId());
            data.put("slotIndex", slotIndex);
            data.put("date", dateAtStartOfDay);
            data.put("startDateTime", startTimestamp);
            data.put("endTime", dto.getEndTime());
            data.put("meetingLink", dto.getMeetingLink());
            data.put("amount", dto.getAmount());
            data.put("status", dto.getStatus() == null ? 0 : dto.getStatus());
            data.put("paymentIntentId", dto.getPaymentIntentId());
            data.put("timeSlotId", String.valueOf(slotIndex));
            data.put("rated", dto.getRated() != null ? dto.getRated() : false);

            transaction.set(appointmentRef, data);

            appointmentDto created = new appointmentDto();
            created.setAppointmentId(appointmentRef.getId());
            created.setCaregiverId(dto.getCaregiverId());
            created.setDoctorId(dto.getDoctorId());
            created.setChildId(dto.getChildId());
            created.setTimeSlotId(String.valueOf(slotIndex));
            created.setStartDateTime(startTimestamp);
            created.setEndTime(dto.getEndTime());
            created.setMeetingLink(dto.getMeetingLink());
            created.setAmount(dto.getAmount());
            created.setStatus(dto.getStatus() == null ? 0 : dto.getStatus());
            created.setPaymentIntentId(dto.getPaymentIntentId());

            return created;
        });

        return future.get();
    }

    /**
     * Delete appointment atomically and remove its slot lock.
     */
    public void deleteByIdAtomically(String appointmentId)
            throws ExecutionException, InterruptedException {

        if (appointmentId == null || appointmentId.isBlank()) {
            throw new IllegalArgumentException("appointmentId is required");
        }

        DocumentReference appointmentRef = firestore.collection(COLLECTION).document(appointmentId);

        ApiFuture<Void> future = firestore.runTransaction(transaction -> {
            DocumentSnapshot appointmentSnap = transaction.get(appointmentRef).get();

            if (!appointmentSnap.exists()) {
                throw new IllegalArgumentException("الموعد غير موجود");
            }

            String doctorId = appointmentSnap.getString("doctorId");
            String date = getDateAsYyyyMmDd(appointmentSnap);

            Object slotIndexObj = appointmentSnap.get("slotIndex");
            int slotIndex = -1;
            if (slotIndexObj instanceof Number) {
                slotIndex = ((Number) slotIndexObj).intValue();
            } else if (slotIndexObj != null) {
                slotIndex = Integer.parseInt(slotIndexObj.toString());
            }

            if (doctorId != null && date != null && slotIndex >= 0) {
                String lockId = buildSlotLockId(doctorId, date, slotIndex);
                DocumentReference lockRef = firestore.collection(SLOT_LOCKS_COLLECTION).document(lockId);
                transaction.delete(lockRef);
            }

            transaction.delete(appointmentRef);
            return null;
        });

        future.get();
    }

    /**
     * Find appointment by its document ID.
     */
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

    private appointmentDto mapDocToDto(DocumentSnapshot doc) {
        appointmentDto dto = new appointmentDto();
        dto.setAppointmentId(doc.getId());
        dto.setCaregiverId(getString(doc, "caregiverId"));
        dto.setChildId(getString(doc, "childId"));
        dto.setDoctorId(getString(doc, "doctorId"));
        dto.setTimeSlotId(getString(doc, "timeSlotId"));
        dto.setStartDateTime(getStartDateTime(doc));
        dto.setEndTime(getString(doc, "endTime"));
        dto.setStatus(getStatusAsInt(doc));
        dto.setMeetingLink(getString(doc, "meetingLink"));
        dto.setAmount(doc.getLong("amount"));
        dto.setPaymentIntentId(getString(doc, "paymentIntentId"));
        dto.setRated(doc.getBoolean("rated")); //Rating

        return dto;
    }

    private Timestamp getStartDateTime(DocumentSnapshot doc) {
        Object raw = doc.get("startDateTime");

        if (raw instanceof Timestamp) {
            return (Timestamp) raw;
        }

        return buildStartDateTime(doc);
    }

    /**
     * Combine the document's date and slot index into one timestamp.
     */
    private Timestamp buildStartDateTime(DocumentSnapshot doc) {
        String dateStr = getDateAsYyyyMmDd(doc);
        if (dateStr == null || dateStr.isEmpty()) {
            return null;
        }

        int slotIndex = TimeSlotConfig.parseSlotIndex(getSlotIndexForDerivation(doc));
        if (slotIndex < 0 || slotIndex >= TimeSlotConfig.SLOT_COUNT) {
            return null;
        }

        LocalDate date = LocalDate.parse(dateStr, DateTimeFormatter.ISO_LOCAL_DATE);
        LocalDateTime ldt = date.atTime(TimeSlotConfig.slotStart(slotIndex));
        return Timestamp.of(Date.from(ldt.atZone(ZONE).toInstant()));
    }

    /**
     * Read date from document (Timestamp/Date only). Returns yyyy-MM-dd or null.
     */
    private static String getDateAsYyyyMmDd(DocumentSnapshot doc) {
        Date d = asDate(doc.get("date"));
        if (d == null) {
            return null;
        }
        return d.toInstant()
                .atZone(ZONE)
                .toLocalDate()
                .format(DateTimeFormatter.ISO_LOCAL_DATE);
    }

    private static Date asDate(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Date) {
            return (Date) v;
        }

        try {
            Object o = v.getClass().getMethod("toDate").invoke(v);
            return o instanceof Date ? (Date) o : null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Status stored as number in DB: 0 or 1.
     */
    private static int getStatusAsInt(DocumentSnapshot doc) {
        Object v = doc.get("status");
        if (v instanceof Number) {
            return ((Number) v).intValue() == 1 ? 1 : 0;
        }
        if (v != null && "1".equals(v.toString().trim())) {
            return 1;
        }
        return 0;
    }

    /**
     * Slot index (0-9) as string for time derivation.
     */
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

    // Update Rating
    public void updateRating(String appointmentId) {
        DocumentReference appointmentRef = firestore.collection(COLLECTION).document(appointmentId);

        Map<String, Object> updates = new HashMap<>();
        updates.put("rated", true);

        appointmentRef.update(updates);
    }
    public void markAsPresent(String appointmentId) {
    if (appointmentId == null || appointmentId.isBlank()) {
        throw new IllegalArgumentException("appointmentId is required");
    }

    DocumentReference appointmentRef = firestore.collection(COLLECTION).document(appointmentId);

    Map<String, Object> updates = new HashMap<>();
    updates.put("status", 1);

    appointmentRef.update(updates);
}
}