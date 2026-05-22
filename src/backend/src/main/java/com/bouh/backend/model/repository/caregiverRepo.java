package com.bouh.backend.model.repository;
import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.Dto.childDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityDayDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityStoredSlotDto;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.google.firebase.auth.FirebaseAuth;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutionException;

@Slf4j // for log debugging
@Repository
public class caregiverRepo {

    // springBoot on config it will inject the globally created FireStore bean
    // (in Config File) into this Repo instance of fireStore
    private final Firestore firestore;
    private final AppointmentRepo appointmentRepo;
    private final AvailabilityScheduleRepo availabilityScheduleRepo;

    public caregiverRepo(Firestore firestore, AppointmentRepo appointmentRepo,AvailabilityScheduleRepo availabilityScheduleRepo ) {
        this.firestore = firestore; // set the instance so this repo use it
        this.appointmentRepo = appointmentRepo;
        this.availabilityScheduleRepo = availabilityScheduleRepo;
    }

    /*
     * Creates a caregiver Account
     */
    public void createCaregiver(String uid, caregiverDto dto) {
        try {
            // to prevent having a caregiver without connecting it to its children
            WriteBatch batch = firestore.batch();

            DocumentReference caregiverRef = firestore.collection("caregivers").document(uid);

            Map<String, Object> caregiverData = new HashMap<>();
            caregiverData.put("caregiverId", uid);
            caregiverData.put("name", dto.getName() != null ? dto.getName() : "");
            caregiverData.put("email", dto.getEmail());
            caregiverData.put("fcmToken", dto.getFcmToken());
            caregiverData.put("isActivated", true);

            batch.set(caregiverRef, caregiverData);

            if (dto.getChildren() != null) {

                for (childDto child : dto.getChildren()) {

                    String childId = UUID.randomUUID().toString();
                    DocumentReference childRef = caregiverRef.collection("children").document(childId);
                    Map<String, Object> childData = Map.of(
                            "childId", childId,
                            "name", child.getName(),
                            "dateOfBirth", ConvertChildDOB(child.getDateOfBirth()),
                            "gender", child.getGender(),
                            "createdAt", FieldValue.serverTimestamp());

                    batch.set(childRef, childData);
                }
            }
            // commit everything atomically
            batch.commit().get();

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Batch operation interrupted", e);
        } catch (ExecutionException e) {
            throw new RuntimeException("Batch write failed", e.getCause());
        }
    }

    /*
     * checks if a caregiver exists
     */
    public boolean existsByUid(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("caregivers")
                    .document(uid)
                    .get()
                    .get();

            return snapshot.exists();

        } catch (Exception e) {
            log.error("Failed to check caregiver existence for uid={}", uid, e);
            throw new RuntimeException("Existence check failed", e);
        }
    }

    /*
     * Soft Deletes a caregiver
     */
    public void deleteCaregiver(String uid) {
        try {

            // Delete any upcoming appointments without a refund
            List<appointmentDto> upcoming = appointmentRepo.findUpcomingByCaregiverId(uid);
            for (appointmentDto appt : upcoming) {
                try {
                    unlockAvailabilitySlot(appt);
                    appointmentRepo.deleteByIdAtomically(appt.getAppointmentId());
                } catch (Exception e) {
                    log.error("Failed to delete appointment id={} for caregiver uid={}: {}",
                            appt.getAppointmentId(), uid, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch upcoming appointments for caregiver uid={}: {}", uid, e.getMessage());
        }

        try {
            DocumentReference caregiverRef = firestore.collection("caregivers").document(uid);

            // soft-delete: keep data, mark as deactivated
            caregiverRef.update("isActivated", false,
                    "email", FieldValue.delete(),
                    "fcmToken", FieldValue.delete()).get();

            // delete Firebase Authentication account
            FirebaseAuth.getInstance().deleteUser(uid);

        } catch (Exception e) {
            log.error("Failed to delete caregiver account for uid={}", uid, e);
            throw new RuntimeException("Failed to delete caregiver account", e);
        }
    }

    private void unlockAvailabilitySlot(appointmentDto appt) {

        Timestamp startTs = appt.getStartDateTime();
        String doctorId = appt.getDoctorId();

        if (doctorId == null || doctorId.isBlank() || startTs == null)
            return;

        ZonedDateTime start = ZonedDateTime.ofInstant(
                Instant.ofEpochSecond(startTs.getSeconds(), startTs.getNanos()),
                ZoneId.of("Asia/Riyadh"));

        String date = start.toLocalDate().format(DateTimeFormatter.ISO_LOCAL_DATE);

        int slotIndex = TimeSlotConfig.getSlotIndexForStartTime(start.toLocalTime());

        if (slotIndex < 0)
            return;

        AvailabilityDayDto day = availabilityScheduleRepo.getDay(doctorId, date);

        if (day == null || day.getSlots() == null)
            return;

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
                new HashSet<>());
    }

    public Timestamp ConvertChildDOB(LocalDate childDob) {
        if (childDob == null) {
            return null;
        }
        return Timestamp.of(
                Date.from(
                        childDob.atStartOfDay(ZoneId.systemDefault())
                                .toInstant()));
    }

    public void updateFcmToken(String uid, String fcmToken) {
        try {
            firestore.collection("caregivers")
                    .document(uid)
                    .update("fcmToken", fcmToken)
                    .get();
        } catch (Exception e) {
            log.error("Failed to update caregiver FCM token for uid={}", uid, e);
            throw new RuntimeException("Failed to update caregiver FCM token", e);
        }
    }

    public void clearFcmToken(String uid) {
        try {
            firestore.collection("caregivers")
                    .document(uid)
                    .update("fcmToken", FieldValue.delete())
                    .get();
        } catch (Exception e) {
            log.error("Failed to clear caregiver FCM token for uid={}", uid, e);
            throw new RuntimeException("Failed to clear caregiver FCM token", e);
        }
    }

    /*
     * Returns caregiver profile Info Id,email,name,fcmToken
     */
    public caregiverDto findByUid(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("caregivers")
                    .document(uid)
                    .get()
                    .get();

            if (!snapshot.exists())
                return null;

            // Manually map fields to avoid toObject() silently missing fields
            caregiverDto dto = new caregiverDto();
            dto.setCaregiverId(snapshot.getId());
            dto.setName(snapshot.getString("name"));
            dto.setEmail(snapshot.getString("email"));
            dto.setFcmToken(snapshot.getString("fcmToken"));
            return dto;

        } catch (Exception e) {
            log.error("Failed to fetch caregiver for uid={}", uid);
            log.error("Exception type: {}", e.getClass().getName());
            log.error("Message: {}", e.getMessage());
            throw new RuntimeException("caregiver fetch failed", e);
        }
    }

}