package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.DoctorScheduleDto;
import com.bouh.backend.model.Dto.TimeSlotDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;
import com.google.cloud.firestore.DocumentReference;
import java.util.concurrent.ExecutionException;


@Slf4j // for log debugging
@Repository
public class doctorRepo {

    // Spring Boot will inject the globally created Firestore bean (from Config)
    private final Firestore firestore;

    public doctorRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    public void createDoctor(String uid, doctorDto dto) {
        try {
            firestore
                    .collection("doctors")
                    .document(uid)
                    .set(dto)
                    .get(); // wait for completion (important for error visibility)

        } catch (Exception e) {
            // Log with context (VERY important for debugging)
            log.error("Failed to create doctor profile for uid={}", uid, e);

            // Re-throw so higher layers can react
            throw new RuntimeException("Failed to create doctor profile", e);
        }
    }

    public doctorDto findByUid(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("doctors")
                    .document(uid)
                    .get()
                    .get();

            if (snapshot.exists()) {
                // Maps the doctor document into doctorDto
                return snapshot.toObject(doctorDto.class);
            }

            return null;

        } catch (Exception e) {
            log.error("Failed to fetch doctor for uid={}", uid, e);
            throw new RuntimeException("Doctor fetch failed", e);
        }
    }

    /**
     * Read doctor document from doctors/{doctorId}.
     * Returns name, areaOfKnowledge, profilePhotoURL.
     */
    public doctorDto findById(String doctorId)
            throws ExecutionException, InterruptedException {

        DocumentReference ref =
                firestore.collection("doctors").document(doctorId);

        DocumentSnapshot doc = ref.get().get();

        if (doc == null || !doc.exists()) {
            return null;
        }

        doctorDto dto = new doctorDto();
        dto.setDoctorId(doctorId);
        dto.setName(getString(doc, "name"));
        dto.setAreaOfKnowledge(getString(doc, "areaOfKnowledge"));
        dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));

        return dto;
    }
    /**
     * Returns list of approved doctors for caregiver browsing screen.
     */
    public java.util.List<com.bouh.backend.model.Dto.DoctorSummaryDto>
    getDoctorsForCaregiverList() throws ExecutionException, InterruptedException {

        var result = new java.util.ArrayList<com.bouh.backend.model.Dto.DoctorSummaryDto>();

        var querySnapshot = firestore.collection("doctors").get().get();

        for (DocumentSnapshot doc : querySnapshot.getDocuments()) {

            // IMPORTANT: show only approved doctors (change the status in phase 3 when we have the admin logic) For now, we can set the registrationStatus field to "approved" manually in Firestore for testing.
            String status = getString(doc, "registrationStatus");
            if (status == null || !status.equalsIgnoreCase("approved")) {
                continue;
            }

            var dto = new com.bouh.backend.model.Dto.DoctorSummaryDto();
            dto.setDoctorID(doc.getId());
            dto.setName(getString(doc, "name"));
            dto.setAreaOfKnowledge(getString(doc, "areaOfKnowledge"));

            Object raw = doc.get("rating");
            System.out.println("🔥 rating raw = " + raw);
            System.out.println("🔥 rating type = " + (raw == null ? "null" : raw.getClass()));

          double avg = getDouble(doc, "rating");
if (avg == 0.0) { // لو ما لقا rating أو كان null
    avg = getDouble(doc, "averageRating");
}
dto.setAverageRating(avg);

            dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));

            if (doc.getId().equals("doc_3")) {
                System.out.println("===== DOC_3 DEBUG =====");
                System.out.println("doc_3 data = " + doc.getData());
                System.out.println("rating = " + doc.get("rating") + " type=" +
                        (doc.get("rating")==null ? "null" : doc.get("rating").getClass()));
                System.out.println("averageRating = " + doc.get("averageRating") + " type=" +
                        (doc.get("averageRating")==null ? "null" : doc.get("averageRating").getClass()));
                System.out.println("=======================");
            }

            result.add(dto);
        }

        return result;
    }
/**
 * Returns full doctor details for Doctor Details screen.
 */
public com.bouh.backend.model.Dto.DoctorDetailsDto
getDoctorDetails(String doctorId)
        throws ExecutionException, InterruptedException {

    DocumentReference ref = firestore.collection("doctors").document(doctorId);
    DocumentSnapshot doc = ref.get().get();

    if (doc == null || !doc.exists()) {
        return null;
    }

    var dto = new com.bouh.backend.model.Dto.DoctorDetailsDto();
    dto.setDoctorID(doctorId);
    dto.setName(getString(doc, "name"));
    dto.setAreaOfKnowledge(getString(doc, "areaOfKnowledge"));

    double avg = getDouble(doc, "rating");
if (avg == 0.0) { // لو ما لقا rating أو كان null
    avg = getDouble(doc, "averageRating");
}
dto.setAverageRating(avg);

    Long years = doc.getLong("yearsOfExperience");
    dto.setYearsOfExperience(years == null ? 0 : years.intValue());

    dto.setQualifications(getString(doc, "qualifications"));
    dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));

    return dto;
}
public DoctorScheduleDto getDoctorScheduleByDate(String doctorId, String date)
        throws ExecutionException, InterruptedException {

    var scheduleRef = firestore.collection("doctors")
            .document(doctorId)
            .collection("schedule")
            .document(date);

    var scheduleDoc = scheduleRef.get().get();
    if (scheduleDoc == null || !scheduleDoc.exists()) {
        return null;
    }

    // read timeSlots subcollection
    var slotsSnap = scheduleRef.collection("TimeSlots").get().get();

    var slots = new java.util.ArrayList<TimeSlotDto>();
    for (var slotDoc : slotsSnap.getDocuments()) {
        
        TimeSlotDto slot = slotDoc.toObject(TimeSlotDto.class);

   
        if (slot != null) {
            slots.add(slot);
        }
    }

    var dto = new DoctorScheduleDto();
    dto.setDate(date);
    dto.setTimeSlots(slots);
    return dto;
}
    private static String getString(DocumentSnapshot doc, String field) {
        Object value = doc.get(field);
        return value == null ? null : value.toString();
    }
    private static double getDouble(DocumentSnapshot doc, String field) {
    Object v = doc.get(field);
    if (v == null) return 0.0;

    if (v instanceof Number) {
        return ((Number) v).doubleValue(); //  Long/Int/Double
    }

    try {
        return Double.parseDouble(v.toString()); 
    } catch (Exception e) {
        return 0.0;
    }
}
}
