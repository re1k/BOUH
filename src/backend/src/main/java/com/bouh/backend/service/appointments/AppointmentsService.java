package com.bouh.backend.service.appointments;

import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.caregiverDto;
import com.google.cloud.Timestamp;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.childrenRepo;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;
import com.bouh.backend.model.Dto.appointmentCreateRequestDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityDayDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityStoredSlotDto;
import com.bouh.backend.model.repository.AvailabilityScheduleRepo;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.time.Duration;
import org.springframework.beans.factory.annotation.Value;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import lombok.extern.slf4j.Slf4j;
/**
 * Service for Upcoming and Previous appointments. Time from TimeSlotConfig only
 * (slot index).
 * Status: 0: ABSENT, 1: PRESENT. Order: newest to oldest.
 */
@Slf4j
@Service
public class AppointmentsService {
    // Add these fields at the top of the class, with the other fields
    private final HttpClient httpClient;

    @Value("${bouh.cloud-function.booking-url:}")
    private String bookingFunctionUrl;

    
    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");
    private static final DateTimeFormatter TIME_NO_AMPM = DateTimeFormatter.ofPattern("h:mm");

    private final AppointmentRepo appointmentRepo;
    private final doctorRepo doctorRepo;
    private final childrenRepo childrenRepo;
    private final caregiverRepo caregiverRepo;
    private final AvailabilityScheduleRepo availabilityScheduleRepo;

   public AppointmentsService(
        AppointmentRepo appointmentRepo,
        doctorRepo doctorRepo,
        childrenRepo childrenRepo,
        caregiverRepo caregiverRepo,
        AvailabilityScheduleRepo availabilityScheduleRepo) {
    this.appointmentRepo = appointmentRepo;
    this.doctorRepo = doctorRepo;
    this.childrenRepo = childrenRepo;
    this.caregiverRepo = caregiverRepo;
    this.availabilityScheduleRepo = availabilityScheduleRepo;
    this.httpClient = HttpClient.newHttpClient();
}

    /**
     * Upcoming: date >= today, excluding same-day slots whose end time has passed.
     * Order: nearest first.
     */
    public List<upcomingAppointmentDto> getUpcomingAppointments(String caregiverId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> docs = appointmentRepo.findByCaregiverIdAndDateFromToday(caregiverId);
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        docs.removeIf(d -> isTodaySlotPassed(d, today, now));
        sortNearestFirst(docs);
        return buildViewDtos(docs);
    }

    /**
     * Previous: date < today plus same-day appointments whose slot end time has
     * passed. Order: newest to oldest.
     */
    public List<upcomingAppointmentDto> getPreviousAppointments(String caregiverId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> past = appointmentRepo.findByCaregiverIdAndDateBeforeToday(caregiverId);
        List<appointmentDto> fromToday = appointmentRepo.findByCaregiverIdAndDateFromToday(caregiverId);
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        for (appointmentDto d : fromToday) {
            if (isTodaySlotPassed(d, today, now))
                past.add(d);
        }
        sortNewestFirst(past);
        return buildViewDtos(past);
    }


    public List<upcomingAppointmentDto> getUpcomingAppointmentsByDoctor(String doctorId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> docs = appointmentRepo.findByDoctorIdAndDateFromToday(doctorId);
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        docs.removeIf(d -> isTodaySlotPassed(d, today, now));
        sortNearestFirst(docs);
        return buildViewDtosForDoctor(docs);
    }

    public List<upcomingAppointmentDto> getPreviousAppointmentsByDoctor(String doctorId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> past = appointmentRepo.findByDoctorIdAndDateBeforeToday(doctorId);
        List<appointmentDto> fromToday = appointmentRepo.findByDoctorIdAndDateFromToday(doctorId);
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        for (appointmentDto d : fromToday) {
            if (isTodaySlotPassed(d, today, now))
                past.add(d);
        }
        sortNewestFirst(past);
        return buildViewDtosForDoctor(past);
    }


    private List<upcomingAppointmentDto> buildViewDtosForDoctor(List<appointmentDto> docs)
            throws ExecutionException, InterruptedException {
        if (docs.isEmpty())
            return new ArrayList<>();
        Set<String> caregiverIds = new HashSet<>();
        Set<String> childKeys = new HashSet<>();
        for (appointmentDto d : docs) {
            if (d.getCaregiverId() != null)
                caregiverIds.add(d.getCaregiverId());
            if (d.getCaregiverId() != null && d.getChildId() != null)
                childKeys.add(d.getCaregiverId() + ":" + d.getChildId());
        }
        Map<String, CompletableFuture<String>> caregiverFutures = new HashMap<>();
        for (String cgId : caregiverIds) {
            String id = cgId;
            caregiverFutures.put(id, CompletableFuture.supplyAsync(() -> {
                try {
                    caregiverDto cg = caregiverRepo.findByUid(id);
                    return cg != null ? cg.getName() : null;
                } catch (Exception e) {
                    return null;
                }
            }));
        }
        Map<String, CompletableFuture<String>> childFutures = new HashMap<>();
        for (String key : childKeys) {
            int i = key.indexOf(':');
            String cgId = key.substring(0, i);
            String chId = key.substring(i + 1);
            childFutures.put(key, CompletableFuture.supplyAsync(() -> {
                try {
                    String n = childrenRepo.findChildName(cgId, chId);
                    return n != null ? n : "";
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }));
        }
        List<CompletableFuture<?>> all = new ArrayList<>();
        all.addAll(caregiverFutures.values());
        all.addAll(childFutures.values());
        CompletableFuture.allOf(all.toArray(new CompletableFuture[0])).join();
        Map<String, String> caregiverNameCache = new HashMap<>();
        caregiverFutures.forEach((id, f) -> caregiverNameCache.put(id, f.join()));
        Map<String, String> childNameCache = new HashMap<>();
        childFutures.forEach((k, f) -> childNameCache.put(k, f.join()));

        List<upcomingAppointmentDto> result = new ArrayList<>(docs.size());
        for (appointmentDto doc : docs) {
            String caregiverName = doc.getCaregiverId() != null ? caregiverNameCache.get(doc.getCaregiverId()) : null;
            String cacheKey = doc.getCaregiverId() != null && doc.getChildId() != null
                    ? doc.getCaregiverId() + ":" + doc.getChildId()
                    : null;
            String childName = cacheKey != null ? childNameCache.get(cacheKey) : null;
            if ("".equals(childName))
                childName = null;
            Timestamp startDt = doc.getStartDateTime();
            String dateStr = null;
            String[] displayTimes = new String[] { null, null };
            if (startDt != null) {
                ZonedDateTime zdt = ZonedDateTime
                        .ofInstant(Instant.ofEpochSecond(startDt.getSeconds(), startDt.getNanos()), ZONE);
                dateStr = zdt.toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
                int slotIdx = TimeSlotConfig.getSlotIndexForStartTime(zdt.toLocalTime());
                displayTimes = formatTimesFromSlotIndex(slotIdx >= 0 ? String.valueOf(slotIdx) : null);
            }
            upcomingAppointmentDto dto = new upcomingAppointmentDto();
            dto.setAppointmentId(doc.getAppointmentId());
            dto.setDate(dateStr);
            dto.setStartTime(displayTimes[0]);
            dto.setEndTime(displayTimes[1]);
            dto.setCaregiverName(caregiverName);
            dto.setChildName(childName);
            dto.setStatus(doc.getStatus() != null && doc.getStatus() == 1 ? 1 : 0);
            dto.setMeetingLink(doc.getMeetingLink());
            dto.setPaymentIntentId(doc.getPaymentIntentId());
            result.add(dto);
        }
        return result;
    }

    // True if the appointment is today and its slot has already ended.
    private static boolean isTodaySlotPassed(appointmentDto d, String today, LocalTime now) {
        Timestamp t = d.getStartDateTime();
        if (t == null)
            return false;
        ZonedDateTime zdt = ZonedDateTime.ofInstant(Instant.ofEpochSecond(t.getSeconds(), t.getNanos()), ZONE);
        if (!today.equals(zdt.toLocalDate().toString()))
            return false;
        int idx = TimeSlotConfig.getSlotIndexForStartTime(zdt.toLocalTime());
        if (idx < 0 || idx >= TimeSlotConfig.SLOT_COUNT)
            return false;
        LocalTime slotEnd = TimeSlotConfig.slotEnd(idx);
        return !slotEnd.isAfter(now);
    }

    // Sort by start time, soonest first.
    private static void sortNearestFirst(List<appointmentDto> list) {
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.naturalOrder())));
    }

    // Sort by start time, newest first.
    private static void sortNewestFirst(List<appointmentDto> list) {
        list.sort(Comparator.comparing(appointmentDto::getStartDateTime,
                Comparator.nullsLast(Comparator.reverseOrder())));
    }

    /**
     * Build response DTOs. Fetches all unique doctors and all unique children in
     * parallel,
     * then builds the list. So total time ≈ one batch of doctor reads + one batch
     * of child reads (parallel).
     */
    private List<upcomingAppointmentDto> buildViewDtos(List<appointmentDto> docs)
            throws ExecutionException, InterruptedException {
        if (docs.isEmpty())
            return new ArrayList<>();

        Set<String> doctorIds = new HashSet<>();
        Set<String> childKeys = new HashSet<>();
        for (appointmentDto d : docs) {
            if (d.getDoctorId() != null)
                doctorIds.add(d.getDoctorId());
            if (d.getCaregiverId() != null && d.getChildId() != null)
                childKeys.add(d.getCaregiverId() + ":" + d.getChildId());
        }

        // Fetch all doctors in parallel
        Map<String, CompletableFuture<doctorDto>> doctorFutures = new HashMap<>();
        for (String id : doctorIds) {
            String doctorId = id;
            doctorFutures.put(doctorId, CompletableFuture.supplyAsync(() -> {
                try {
                    return doctorRepo.findByUid(doctorId);
                } catch (Exception e) {
                    return null;
                }
            }));
        }
        // Fetch all children in parallel (same time as doctors)
        Map<String, CompletableFuture<String>> childFutures = new HashMap<>();
        for (String key : childKeys) {
            int i = key.indexOf(':');
            String cgId = key.substring(0, i);
            String chId = key.substring(i + 1);
            childFutures.put(key, CompletableFuture.supplyAsync(() -> {
                try {
                    String n = childrenRepo.findChildName(cgId, chId);
                    return n != null ? n : "";
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            }));
        }

        List<CompletableFuture<?>> all = new ArrayList<>();
        all.addAll(doctorFutures.values());
        all.addAll(childFutures.values());
        CompletableFuture.allOf(all.toArray(new CompletableFuture[0])).join();

        Map<String, doctorDto> doctorCache = new HashMap<>();
        doctorFutures.forEach((id, f) -> doctorCache.put(id, f.join()));
        Map<String, String> childNameCache = new HashMap<>();
        childFutures.forEach((k, f) -> childNameCache.put(k, f.join()));

        List<upcomingAppointmentDto> result = new ArrayList<>(docs.size());
        for (appointmentDto doc : docs) {
            doctorDto doctor = doc.getDoctorId() != null ? doctorCache.get(doc.getDoctorId()) : null;
            String cacheKey = doc.getCaregiverId() != null && doc.getChildId() != null
                    ? doc.getCaregiverId() + ":" + doc.getChildId()
                    : null;
            String childName = cacheKey != null ? childNameCache.get(cacheKey) : null;
            if ("".equals(childName))
                childName = null;
            // Get date and display times (e.g. "8:30", "9:00") from the single
            // startDateTime.
            Timestamp startDt = doc.getStartDateTime();
            String dateStr = null;
            String[] displayTimes = new String[] { null, null };
            if (startDt != null) {
                ZonedDateTime zdt = ZonedDateTime
                        .ofInstant(Instant.ofEpochSecond(startDt.getSeconds(), startDt.getNanos()), ZONE);
                dateStr = zdt.toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
                int slotIdx = TimeSlotConfig.getSlotIndexForStartTime(zdt.toLocalTime());
                displayTimes = formatTimesFromSlotIndex(slotIdx >= 0 ? String.valueOf(slotIdx) : null);
            }

            upcomingAppointmentDto dto = new upcomingAppointmentDto();
            dto.setAppointmentId(doc.getAppointmentId());
            dto.setDate(dateStr);
            dto.setStartTime(displayTimes[0]);
            dto.setEndTime(displayTimes[1]);
            dto.setDoctorName(doctor != null ? doctor.getName() : null);
            dto.setDoctorAreaOfKnowledge(doctor != null ? doctor.getAreaOfKnowledge() : null);
            dto.setDoctorProfilePhotoURL(doctor != null ? doctor.getProfilePhotoURL() : null);
            dto.setChildName(childName);
            dto.setStatus(doc.getStatus() != null && doc.getStatus() == 1 ? 1 : 0);
            dto.setMeetingLink(doc.getMeetingLink());
            dto.setPaymentIntentId(doc.getPaymentIntentId());
            result.add(dto);
        }
        return result;
    }

    /**
     * Derive 12-hour display times from slot index (0-9) using TimeSlotConfig only.
     * appointment startTime is the slot index (stored as string in DTO, e.g. "3").
     * Returns { startTime12h, endTime12h }; nulls if index invalid.
     */
    private static String[] formatTimesFromSlotIndex(String slotIndexStr) {
        int index = TimeSlotConfig.parseSlotIndex(slotIndexStr);
        if (index < 0 || index >= TimeSlotConfig.SLOT_COUNT) {
            return new String[] { null, null };
        }
        LocalTime start = TimeSlotConfig.slotStart(index);
        LocalTime end = TimeSlotConfig.slotEnd(index);
        return new String[] { start.format(TIME_NO_AMPM), end.format(TIME_NO_AMPM) };
    }

    private static int parseSlotIndex(String slotIndexStr) {
        if (slotIndexStr == null || slotIndexStr.isBlank()) return -1;
        try {
            int idx = Integer.parseInt(slotIndexStr.trim());
            return (idx >= 0 && idx < TimeSlotConfig.SLOT_COUNT) ? idx : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }
    public appointmentDto createAppointment(String caregiverId, appointmentCreateRequestDto request)
        throws ExecutionException, InterruptedException {

    if (caregiverId == null || caregiverId.isBlank()) {
        throw new IllegalArgumentException("Caregiver not authenticated");
    }

    if (request.getDoctorId() == null || request.getDoctorId().isBlank()) {
        throw new IllegalArgumentException("doctorId is required");
    }

    if (request.getChildId() == null || request.getChildId().isBlank()) {
        throw new IllegalArgumentException("childId is required");
    }

    if (request.getDate() == null || request.getDate().isBlank()) {
        throw new IllegalArgumentException("date is required");
    }

    if (request.getSlotIndex() == null ||
            request.getSlotIndex() < 0 ||
            request.getSlotIndex() >= TimeSlotConfig.SLOT_COUNT) {
        throw new IllegalArgumentException("Invalid slotIndex");
    }

    if (request.getPaymentIntentId() == null || request.getPaymentIntentId().isBlank()) {
        throw new IllegalArgumentException("paymentIntentId is required");
    }

    // 1) check caregiver doesn't have another appointment at the same date and slot
    boolean hasConflict = appointmentRepo.caregiverHasConflict(
            caregiverId,
            request.getDate(),
            request.getSlotIndex()
    );

    if (hasConflict) {
        throw new IllegalStateException("يوجد لديك موعد آخر في نفس التاريخ والوقت");
    }

    // 2) check doctor availability for the requested date and slot
    AvailabilityDayDto day = availabilityScheduleRepo.getDay(request.getDoctorId(), request.getDate());

    if (day == null || day.getSlots() == null || day.getSlots().isEmpty()) {
        throw new IllegalStateException("هذا الموعد غير متاح");
    }

    AvailabilityStoredSlotDto targetSlot = null;
    for (AvailabilityStoredSlotDto slot : day.getSlots()) {
        if (slot.getIndex() == request.getSlotIndex()) {
            targetSlot = slot;
            break;
        }
    }

    if (targetSlot == null) {
        throw new IllegalStateException("هذا الموعد غير متاح");
    }

    if (targetSlot.isBooked()) {
        throw new IllegalStateException("تم حجز هذا الموعد مسبقًا");
    }

    // 3) prepare appointment DTO
    appointmentDto dto = new appointmentDto();
    dto.setCaregiverId(caregiverId);
    dto.setDoctorId(request.getDoctorId());
    dto.setChildId(request.getChildId());
    dto.setTimeSlotId(String.valueOf(request.getSlotIndex()));
    dto.setMeetingLink("");
    dto.setAmount(request.getAmount());
    dto.setStatus(0);
    dto.setPaymentIntentId(request.getPaymentIntentId());

    // endTime اختياري للآن، لأن الواجهة تبنيه من slotIndex
    dto.setEndTime(null);

    // 4) Save the appointment
    appointmentDto created = appointmentRepo.create(dto, request.getDate(), request.getSlotIndex());

    // 5) update availability schedule to mark the slot as booked
    targetSlot.setBooked(true);

    Map<String, AvailabilityDayDto> daysToUpdate = new HashMap<>();
    daysToUpdate.put(request.getDate(), day);

    availabilityScheduleRepo.update(
            request.getDoctorId(),
            daysToUpdate,
            new HashSet<>()
    );

    // Notify the doctor if the appointment is within the next hour.
    notifyDoctorAboutNewBooking(created, request.getDate(), request.getSlotIndex());

    return created;
}
public void cancelAppointment(String caregiverId, String appointmentId)
        throws ExecutionException, InterruptedException {

    if (caregiverId == null || caregiverId.isBlank()) {
        throw new IllegalArgumentException("Caregiver not authenticated");
    }

    if (appointmentId == null || appointmentId.isBlank()) {
        throw new IllegalArgumentException("appointmentId is required");
    }

    appointmentDto appointment = appointmentRepo.findById(appointmentId);

    if (appointment == null) {
        throw new IllegalArgumentException("الموعد غير موجود");
    }

   String appointmentCaregiverId = appointment.getCaregiverId();
String appointmentDoctorId = appointment.getDoctorId();

boolean isCaregiverOwner =
        appointmentCaregiverId != null && caregiverId.equals(appointmentCaregiverId);

boolean isDoctorOwner =
        appointmentDoctorId != null && caregiverId.equals(appointmentDoctorId);

if (!isCaregiverOwner && !isDoctorOwner) {
    throw new IllegalStateException("غير مصرح لك بإلغاء هذا الموعد");
}
    Timestamp startTs = appointment.getStartDateTime();
    if (startTs == null) {
        throw new IllegalStateException("تعذر تحديد وقت الموعد");
    }

    ZonedDateTime start = ZonedDateTime.ofInstant(
            Instant.ofEpochSecond(startTs.getSeconds(), startTs.getNanos()),
            ZONE
    );

    ZonedDateTime now = ZonedDateTime.now(ZONE);

    Duration remaining = Duration.between(now, start);

    // مسموح فقط إذا باقي أكثر من 30 دقيقة (انا لبى عدلته عشان الايرور مدري صح ولا لا حطيت الي اقترحه)
    if (remaining.minusMinutes(30).isNegative() || remaining.minusMinutes(30).isZero()) {
        throw new IllegalStateException("لا يمكن إلغاء الموعد قبل أقل من 30 دقيقة من وقت البدء");
    }

    String doctorId = appointment.getDoctorId();
    if (doctorId == null || doctorId.isBlank()) {
        throw new IllegalStateException("تعذر تحديد الدكتور");
    }

    String date = start.toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);
    int slotIndex = TimeSlotConfig.getSlotIndexForStartTime(start.toLocalTime());

    if (slotIndex < 0 || slotIndex >= TimeSlotConfig.SLOT_COUNT) {
        throw new IllegalStateException("تعذر تحديد الفترة الزمنية للموعد");
    }

    AvailabilityDayDto day = availabilityScheduleRepo.getDay(doctorId, date);
    if (day != null && day.getSlots() != null) {
        for (AvailabilityStoredSlotDto slot : day.getSlots()) {
            if (slot.getIndex() == slotIndex) {
                slot.setBooked(false);
                break;
            }
        }

        Map<String, AvailabilityDayDto> daysToUpdate = new HashMap<>();
        daysToUpdate.put(date, day);

        availabilityScheduleRepo.update(
                doctorId,
                daysToUpdate,
                new HashSet<>()
        );
    }

    appointmentRepo.deleteById(appointmentId);
}

    // ─────────────────────────────────────────────────────────────
    // Booking notification helpers
    // ─────────────────────────────────────────────────────────────

    /**
     * Sends a booking notification to the doctor only when the appointment
     * is less than 1 hour away. Builds a human-readable Arabic time string
     * (e.g. "8:30 صباحًا") and delegates to callBookingFunction.
     */
    private void notifyDoctorAboutNewBooking(appointmentDto created, String date, int slotIndex) {
        String doctorId = created.getDoctorId();
        if (doctorId == null || doctorId.isBlank()) return;

        // Reconstruct the appointment start as a ZonedDateTime to measure
        // how far away it is from right now.
        ZonedDateTime appointmentStart = LocalDate
                .parse(date)
                .atTime(TimeSlotConfig.slotStart(slotIndex))
                .atZone(ZONE);
        
        ZonedDateTime appointmentEnd = LocalDate
                .parse(date)
                .atTime(TimeSlotConfig.slotEnd(slotIndex))
                .atZone(ZONE);
        

        ZonedDateTime now = ZonedDateTime.now(ZONE);
        Duration untilStartAppointment = Duration.between(now, appointmentStart);
        Duration untilEndAppointment = Duration.between(now, appointmentEnd);


        // Skip notification if the appointment is in the past or >= 60 minutes away
        if (untilEndAppointment.isNegative() || untilStartAppointment.toMinutes() >= 60) return;

        // Build Arabic time string, e.g. "8:30 صباحًا" or "3:00 مساءً"
        LocalTime startTime = TimeSlotConfig.slotStart(slotIndex);
        String amPm = startTime.getHour() < 12 ? "صباحًا" : "مساءً";
        String timeText = startTime.format(DateTimeFormatter.ofPattern("h:mm")) + " " + amPm;

        callBookingFunction(doctorId, timeText);
    }

    /**
     * POSTs a JSON payload to the booking Cloud Function asynchronously.
     * Async so the appointment creation response is never delayed by this call.
     */
    private void callBookingFunction(String targetUserId, String appointmentStartTime) {
        if (bookingFunctionUrl == null || bookingFunctionUrl.isBlank()) {
            log.warn("Booking cloud function URL not configured, skipping notification.");
            return;
        }

        String json = String.format(
            "{\"targetUserId\":\"%s\",\"targetRole\":\"doctor\",\"appointmentStartTime\":\"%s\"}",
                targetUserId, appointmentStartTime);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(bookingFunctionUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        // Fire-and-forget: if the Cloud Function is temporarily down,
        // the appointment is still created successfully.
        httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenAccept(resp -> log.info("Booking cloud function responded: {} {}", resp.statusCode(), resp.body()))
                .exceptionally(ex -> {
                    log.error("Failed to call booking cloud function: {}", ex.getMessage());
                    return null;
                });
    }

}
