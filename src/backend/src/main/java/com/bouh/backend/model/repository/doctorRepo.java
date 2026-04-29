package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.DoctorScheduleDto;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityStoredSlotDto;
import com.bouh.backend.service.GcsImageService;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.auth.FirebaseAuth;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Repository;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;


@Slf4j // for log debugging
@Repository
public class doctorRepo {

    // Spring Boot will inject the globally created Firestore bean (from Config)
    private final Firestore firestore;
    private final AppointmentRepo appointment;
    private final GcsImageService gcsImageService;

    @Autowired
    private ApplicationContext context;

    public doctorRepo(
            Firestore firestore,
            AppointmentRepo appointment,
            GcsImageService gcsImageService) {

        this.firestore = firestore;
        this.appointment = appointment;
        this.gcsImageService = gcsImageService;
    }

     /*
     * Creates a new doctor account
     */
    public void createDoctor(String uid, doctorDto dto) {
        try {
            // to ensure full write of all fields
            WriteBatch batch = firestore.batch();

            DocumentReference doctorRef = firestore.collection("doctors").document(uid);

            Map<String, Object> doctorData = new HashMap<>();

            doctorData.put("name", dto.getName() != null ? dto.getName() : "");
            doctorData.put("email", dto.getEmail());
            doctorData.put("gender", dto.getGender());
            doctorData.put("areaOfKnowledge", dto.getAreaOfKnowledge());
            doctorData.put("qualifications", cleanQualifications(dto.getQualifications()));
            doctorData.put("yearsOfExperience", dto.getYearsOfExperience());
            doctorData.put("scfhsNumber", dto.getScfhsNumber());
            doctorData.put("iban", dto.getIban());
            doctorData.put("averageRating", 0.0);
            doctorData.put("profilePhotoURL", dto.getProfilePhotoURL());
            doctorData.put("registrationStatus", "PENDING");
            doctorData.put("fcmToken", dto.getFcmToken());
            doctorData.put("isActivated", true );


            batch.set(doctorRef, doctorData);
            batch.commit().get();

        } catch (Exception e) {
            log.error("Failed to create doctor profile for uid={}", uid, e);
            throw new RuntimeException("Failed to create doctor profile", e);
        }
    }

    /*
     * Finds a doctor by ID
     */
    public doctorDto findByUid(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("doctors")
                    .document(uid)
                    .get()
                    .get();

            if (!snapshot.exists())
                return null;

            // Manually map fields to avoid toObject() silently missing fields
            doctorDto dto = new doctorDto();
            dto.setDoctorId(snapshot.getId());
            dto.setName(snapshot.getString("name"));
            dto.setEmail(snapshot.getString("email"));
            dto.setGender(snapshot.getString("gender"));
            dto.setAreaOfKnowledge(snapshot.getString("areaOfKnowledge"));
            dto.setProfilePhotoURL(snapshot.getString("profilePhotoURL"));
            dto.setRegistrationStatus(snapshot.getString("registrationStatus"));
            dto.setFcmToken(snapshot.getString("fcmToken"));
            dto.setScfhsNumber(snapshot.getString("scfhsNumber"));
            dto.setIban(snapshot.getString("iban"));
            dto.setAverageRating(snapshot.getDouble("averageRating"));
            dto.setYearsOfExperience(snapshot.getLong("yearsOfExperience") != null
                    ? snapshot.getLong("yearsOfExperience").intValue()
                    : null);
            return dto;

        } catch (Exception e) {
            log.error("Failed to fetch doctor for uid={}", uid);
            log.error("Exception type: {}", e.getClass().getName());
            log.error("Message: {}", e.getMessage());
            throw new RuntimeException("Doctor fetch failed", e);
        }
    }

    /*
     * Returns list of approved doctors for caregiver browsing screen.
     */
    public java.util.List<com.bouh.backend.model.Dto.DoctorSummaryDto> getDoctorsForCaregiverList()
            throws ExecutionException, InterruptedException {

        var result = new java.util.ArrayList<com.bouh.backend.model.Dto.DoctorSummaryDto>();

        var querySnapshot = firestore.collection("doctors").get().get();

        for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
            System.out.println("doctor id = " + doc.getId());
            System.out.println("name = " + doc.get("name"));
            System.out.println("registrationStatus = " + doc.get("registrationStatus"));
            System.out.println("--------------------");
            // IMPORTANT: show only approved doctors (change the status in phase 3 when we
            // have the admin logic) For now, we can set the registrationStatus field to
            // "approved" manually in Firestore for testing.
            String status = getString(doc, "registrationStatus");
            if (status == null || !status.equalsIgnoreCase("approved")) {
                continue;
            }

            var dto = new com.bouh.backend.model.Dto.DoctorSummaryDto();
            dto.setDoctorID(doc.getId());
            dto.setName(getString(doc, "name"));
            dto.setAreaOfKnowledge(getString(doc, "areaOfKnowledge"));

            Object raw = doc.get("rating");
            System.out.println(" rating raw = " + raw);
            System.out.println(" rating type = " + (raw == null ? "null" : raw.getClass()));

            dto.setAverageRating(getDouble(doc, "averageRating"));

            dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));

            if (doc.getId().equals("doc_3")) {
                System.out.println("===== DOC_3 DEBUG =====");
                System.out.println("doc_3 data = " + doc.getData());
                System.out.println("rating = " + doc.get("rating") + " type=" +
                        (doc.get("rating") == null ? "null" : doc.get("rating").getClass()));
                System.out.println("averageRating = " + doc.get("averageRating") + " type=" +
                        (doc.get("averageRating") == null ? "null" : doc.get("averageRating").getClass()));
                System.out.println("=======================");
            }

            result.add(dto);
        }

        return result;
    }

    /*
     * Returns full doctor details for Doctor Details screen.
     */
    public com.bouh.backend.model.Dto.DoctorDetailsDto getDoctorDetails(String doctorId)
            throws ExecutionException, InterruptedException {

        DocumentReference ref = firestore.collection("doctors").document(doctorId);
        DocumentSnapshot doc = ref.get().get();

        if (doc == null || !doc.exists()) {
            return null;
        }
        System.out.println("===== DOCTOR DETAILS DEBUG =====");
        System.out.println("doctorId = " + doctorId);
        System.out.println("doc data = " + doc.getData());
        System.out.println("yearsOfExperience raw = " + doc.get("yearsOfExperience"));
        System.out.println("yearsOfExperience type = " +
                (doc.get("yearsOfExperience") == null ? "null" : doc.get("yearsOfExperience").getClass()));
        System.out.println("qualifications raw = " + doc.get("qualifications"));
        System.out.println("qualifications type = " +
                (doc.get("qualifications") == null ? "null" : doc.get("qualifications").getClass()));
        System.out.println("===============================");

        var dto = new com.bouh.backend.model.Dto.DoctorDetailsDto();
        dto.setDoctorID(doctorId);
        dto.setName(getString(doc, "name"));
        dto.setAreaOfKnowledge(getString(doc, "areaOfKnowledge"));

        dto.setAverageRating(getDouble(doc, "averageRating"));

        Long years = doc.getLong("yearsOfExperience");
        dto.setYearsOfExperience(years == null ? 0 : years.intValue());

        Object qualificationsObj = doc.get("qualifications");

        if (qualificationsObj instanceof List<?>) {
            List<String> qualifications = ((List<?>) qualificationsObj)
                    .stream()
                    .map(Object::toString)
                    .map(String::trim)
                    .filter(q -> !q.isEmpty())
                    .toList();
            dto.setQualifications(qualifications);

        } else if (qualificationsObj instanceof String) {
            String qualificationsStr = ((String) qualificationsObj).trim();

            if (qualificationsStr.isEmpty()) {
                dto.setQualifications(List.of());
            } else {
                dto.setQualifications(List.of(qualificationsStr));
            }

        } else {
            dto.setQualifications(List.of());
        }
        dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));
        System.out.println("FINAL DTO qualifications = " + dto.getQualifications());
        System.out.println("FINAL DTO yearsOfExperience = " + dto.getYearsOfExperience());
        return dto;
    }

    public DoctorScheduleDto getDoctorScheduleByDate(String doctorId, String date)
            throws ExecutionException, InterruptedException {

        var scheduleRef = firestore.collection("doctors")
                .document(doctorId)
                .collection("schedule")
                .document("current")
                .collection("TimeSlots")
                .document(date);

        var scheduleDoc = scheduleRef.get().get();

        if (scheduleDoc == null || !scheduleDoc.exists()) {
            return new DoctorScheduleDto(date, List.of());
        }

        Object rawSlots = scheduleDoc.get("slots");
        var slots = new java.util.ArrayList<AvailabilityStoredSlotDto>();

        if (rawSlots instanceof List<?>) {
            for (Object item : (List<?>) rawSlots) {
                if (item instanceof Map<?, ?> map) {
                    AvailabilityStoredSlotDto slot = new AvailabilityStoredSlotDto();

                    Object indexObj = map.get("index");
                    Object bookedObj = map.get("booked");

                    if (indexObj instanceof Number) {
                        slot.setIndex(((Number) indexObj).intValue());
                    } else {
                        continue;
                    }

                    slot.setBooked(bookedObj instanceof Boolean && (Boolean) bookedObj);

                    slots.add(slot);
                }
            }
        }

        var dto = new DoctorScheduleDto();
        dto.setDate(date);
        dto.setTimeSlots(slots);

        System.out.println("===== CAREGIVER SCHEDULE DEBUG =====");
        System.out.println("doctorId = " + doctorId);
        System.out.println("date = " + date);
        System.out.println("raw slots = " + rawSlots);
        System.out.println("mapped slots count = " + slots.size());
        System.out.println("===================================");

        return dto;
    }

    private static String getString(DocumentSnapshot doc, String field) {
        Object value = doc.get(field);
        return value == null ? null : value.toString();
    }

    private static double getDouble(DocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        if (v == null)
            return 0.0;

        if (v instanceof Number) {
            return ((Number) v).doubleValue(); // Long/Int/Double
        }

        try {
            return Double.parseDouble(v.toString());
        } catch (Exception e) {
            return 0.0;
        }
    }

    private List<String> cleanQualifications(List<String> qualifications) {
        if (qualifications == null)
            return List.of();

        return qualifications.stream()
                .map(String::trim)
                .filter(q -> !q.isEmpty())
                .limit(12) // safety limit
                .toList();
    }


    /*
     * Checks to allow delete
     */
    public String deleteDoctor(String uid) {

        try {
            doctorDto doctor = findByUid(uid);

            if (doctor == null) {
                throw new RuntimeException("Doctor not found");
            }

            // only check
            List<appointmentDto> upcoming = appointment.findUpcomingByDoctorId(uid);

            if (!upcoming.isEmpty()) {
                return "upcoming-appointment-found";
            }

           // async call via proxy, for faster deletion
           context.getBean(doctorRepo.class).deleteDoctorAsync(uid, doctor);

            return "deleted";

        } catch (Exception e) {
            log.error("Failed to delete doctor with uid={}", uid, e);
            throw new RuntimeException("Failed to delete doctor", e);
        }
    }

    /*
     * Soft Deletes a doctor account
     */
    @Async
    public void deleteDoctorAsync(String uid, doctorDto doctor) {
        try {

             // delete image
           if (doctor.getProfilePhotoURL() != null) {
                 gcsImageService.deleteImage(doctor.getProfilePhotoURL());
            }

            // soft-delete: keep appointments data, and mark as deactivated
            firestore.collection("doctors").document(uid)
                    .update("isActivated", false,
                    "profilePhotoURL",null,
                    "email", FieldValue.delete(),
                    "fcmToken", FieldValue.delete(),
                    "iban", FieldValue.delete(),
                    "gender", FieldValue.delete(),
                    "qualifications", FieldValue.delete(),
                    "yearsOfExperience", FieldValue.delete(),
                    "averageRating",FieldValue.delete()
                 ).get();

            // delete the firebase auth account
            FirebaseAuth.getInstance().deleteUser(uid);

        } catch (Exception e) {
            log.error("Async delete failed for uid={}", uid, e);

        }
    }

    /*
     * Updates FCM tocken
     */
    public void updateFcmToken(String uid, String fcmToken) {
        try {
            firestore.collection("doctors")
                    .document(uid)
                    .update("fcmToken", fcmToken)
                    .get();
        } catch (Exception e) {
            log.error("Failed to update doctor FCM token for uid={}", uid, e);
            throw new RuntimeException("Failed to update doctor FCM token", e);
        }
    }

    /*
     * Sets a new rate from a caregiver and updates the average
     */
    public void addRating(String doctorId, int rating) throws Exception {

        DocumentReference doctorRef = firestore.collection("doctors").document(doctorId);
        DocumentSnapshot snapshot = doctorRef.get().get();

        double average = snapshot.getDouble("averageRating") == null
                ? 0.0
                : snapshot.getDouble("averageRating");

        long total = snapshot.getLong("totalRatings") == null
                ? 0
                : snapshot.getLong("totalRatings");

        double newAverage = ((average * total) + rating) / (total + 1);
        newAverage = Math.round(newAverage * 10.0) / 10.0;

        Map<String, Object> updates = new HashMap<>();
        updates.put("averageRating", newAverage);
        updates.put("totalRatings", total + 1);
        doctorRef.update(updates).get();
    }
}
