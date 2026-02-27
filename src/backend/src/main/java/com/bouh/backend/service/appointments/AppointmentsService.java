package com.bouh.backend.service.appointments;

import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.childRepo;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;

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

/**
 * Service for Upcoming and Previous appointments. Time from TimeSlotConfig only (slot index).
 * Status: 0: ABSENT, 1: PRESENT. Order: newest to oldest.
 */
@Service
public class AppointmentsService {

    private static final ZoneId ZONE = ZoneId.systemDefault();
    private static final DateTimeFormatter TIME_NO_AMPM = DateTimeFormatter.ofPattern("h:mm");

    private final AppointmentRepo appointmentRepo;
    private final doctorRepo doctorRepo;
    private final childRepo childRepo;

    public AppointmentsService(AppointmentRepo appointmentRepo, doctorRepo doctorRepo, childRepo childRepo) {
        this.appointmentRepo = appointmentRepo;
        this.doctorRepo = doctorRepo;
        this.childRepo = childRepo;
    }

    /**
     * Upcoming: date >= today, excluding same-day slots whose end time has passed. Order: nearest first.
     */
    public List<upcomingAppointmentDto> getUpcomingAppointments(String caregiverId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> docs = appointmentRepo.findByCaregiverIdAndDateFromToday(caregiverId);
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        docs.removeIf(d -> isTodaySlotPassed(d.getDate(), d.getStartTime(), today, now));
        sortNearestFirst(docs);
        return buildViewDtos(docs);
    }

    /**
     * Previous: date < today plus same-day appointments whose slot end time has passed. Order: newest to oldest.
     */
    public List<upcomingAppointmentDto> getPreviousAppointments(String caregiverId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> past = appointmentRepo.findByCaregiverIdAndDateBeforeToday(caregiverId);
        List<appointmentDto> fromToday = appointmentRepo.findByCaregiverIdAndDateFromToday(caregiverId);
        String today = ZonedDateTime.now(ZONE).toLocalDate().toString();
        LocalTime now = ZonedDateTime.now(ZONE).toLocalTime();
        for (appointmentDto d : fromToday) {
            if (isTodaySlotPassed(d.getDate(), d.getStartTime(), today, now))
                past.add(d);
        }
        sortNewestFirst(past);
        return buildViewDtos(past);
    }

    /** True if date is today and slot end time (TimeSlotConfig) is <= now. */
    private static boolean isTodaySlotPassed(String date, String slotIndexStr, String today, LocalTime now) {
        if (date == null || !today.equals(date)) return false;
        int idx = parseSlotIndex(slotIndexStr);
        if (idx < 0 || idx >= TimeSlotConfig.SLOT_COUNT) return false;
        LocalTime slotEnd = TimeSlotConfig.slotEnd(idx);
        return !slotEnd.isAfter(now);
    }

    /** Sort by date ascending, then by slot index ascending (nearest upcoming first). Invalid slot index (-1) last. */
    private static void sortNearestFirst(List<appointmentDto> list) {
        list.sort(Comparator
                .comparing(appointmentDto::getDate, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(d -> parseSlotIndex(d.getStartTime()), (a, b) -> {
                    if (a < 0 && b < 0) return 0;
                    if (a < 0) return 1;
                    if (b < 0) return -1;
                    return Integer.compare(a, b);
                }));
    }

    /** Sort by date descending, then by slot index descending (newest first). Invalid slot index (-1) last. */
    private static void sortNewestFirst(List<appointmentDto> list) {
        list.sort(Comparator
                .comparing(appointmentDto::getDate, Comparator.nullsLast(Comparator.reverseOrder()))
                .thenComparing(d -> parseSlotIndex(d.getStartTime()), (a, b) -> {
                    if (a < 0 && b < 0) return 0;
                    if (a < 0) return 1;
                    if (b < 0) return -1;
                    return Integer.compare(b, a);
                }));
    }

    /**
     * Build response DTOs. Fetches all unique doctors and all unique children in parallel,
     * then builds the list. So total time ≈ one batch of doctor reads + one batch of child reads (parallel).
     */
    private List<upcomingAppointmentDto> buildViewDtos(List<appointmentDto> docs)
            throws ExecutionException, InterruptedException {
        if (docs.isEmpty()) return new ArrayList<>();

        Set<String> doctorIds = new HashSet<>();
        Set<String> childKeys = new HashSet<>();
        for (appointmentDto d : docs) {
            if (d.getDoctorId() != null) doctorIds.add(d.getDoctorId());
            if (d.getCaregiverId() != null && d.getChildId() != null)
                childKeys.add(d.getCaregiverId() + ":" + d.getChildId());
        }

        // Fetch all doctors in parallel
        Map<String, CompletableFuture<doctorDto>> doctorFutures = new HashMap<>();
        for (String id : doctorIds) {
            String doctorId = id;
            doctorFutures.put(doctorId, CompletableFuture.supplyAsync(() -> {
                try { return doctorRepo.findById(doctorId); } catch (Exception e) { throw new RuntimeException(e); }
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
                    String n = childRepo.findChildName(cgId, chId);
                    return n != null ? n : "";
                } catch (Exception e) { throw new RuntimeException(e); }
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
                ? doc.getCaregiverId() + ":" + doc.getChildId() : null;
            String childName = cacheKey != null ? childNameCache.get(cacheKey) : null;
            if ("".equals(childName)) childName = null;
            String[] displayTimes = formatTimesFromSlotIndex(doc.getStartTime());

            upcomingAppointmentDto dto = new upcomingAppointmentDto();
            dto.setAppointmentId(doc.getAppointmentId());
            dto.setDate(doc.getDate());
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
        int index = parseSlotIndex(slotIndexStr);
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
}
