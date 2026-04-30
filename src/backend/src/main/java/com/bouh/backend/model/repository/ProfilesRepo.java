package com.bouh.backend.model.repository;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Repository;
import com.google.cloud.Timestamp;
import com.bouh.backend.model.Dto.profiles.caregiverProfileResponseDto;
import com.bouh.backend.model.Dto.profiles.doctorProfileResponseDto;
import com.bouh.backend.model.Dto.profiles.doctorUpdateDto;
import com.bouh.backend.service.GcsImageService;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Repository
@RequiredArgsConstructor
@Slf4j
public class ProfilesRepo {

    private final Firestore firestore;
    private final GcsImageService imageStorageService;

    /** Adds field to map only if value is not null. */
    private void putIfNotNull(Map<String, Object> map, String key, Object value) {
        if (value != null) {
            map.put(key, value);
        }
    }

    /** Cleans qualifications list (trim, remove empty/duplicates, limit size). */
    private List<String> cleanQualifications(List<String> qualifications) {
        if (qualifications == null)
            return null;

        List<String> result = qualifications.stream()
                .map(String::trim)
                .filter(q -> !q.isEmpty())
                .distinct()
                .limit(12)
                .toList();

        return result;
    }

    /** Updates editable doctor fields. */
    public void updateDoctor(String uid, doctorUpdateDto dto) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("doctors")
                    .document(uid)
                    .get()
                    .get();

            if (!snapshot.exists()) {
                throw new RuntimeException("Doctor not found");
            }

            Map<String, Object> updates = new HashMap<>();

            String oldImagePath = snapshot.getString("profilePhotoURL");
            String newImagePath = dto.getProfilePhotoURL();
            
            if (dto.getProfilePhotoURL() != null) {

                String finalImagePath = handleProfileImage(
                        oldImagePath,
                        newImagePath);

                updates.put("profilePhotoURL", finalImagePath);
            }

            putIfNotNull(updates, "name", dto.getName());
            putIfNotNull(updates, "gender", dto.getGender());
            putIfNotNull(updates, "yearsOfExperience", dto.getYearsOfExperience());
            putIfNotNull(updates, "iban", dto.getIban());

            // if (dto.getQualifications() != null) {
            // updates.put("qualifications", cleanQualifications(dto.getQualifications()));
            // }

            if (dto.getQualifications() != null) {
                if (hasPendingRequest(uid)) {
                    throw new RuntimeException("لديك طلب تعديل مؤهلات قيد المراجعة حالياً.");
                }

                List<String> cleanedNew = cleanQualifications(dto.getQualifications());
                List<String> oldQualifications = getQualificationsStringList(snapshot, "qualifications");
                createQualificationEditRequest(uid, oldQualifications, cleanedNew);

                log.info("[[DTO quals]]: {}", dto.getQualifications());
                log.info("[[Cleaned quals]]: {}", cleanedNew);
            }

            if (!updates.isEmpty())
            updateDoctorProfile(uid, updates);

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to update doctor", e);
        }
    }

    /** Applies partial update to doctor document in Firestore. */
    public void updateDoctorProfile(String uid, Map<String, Object> updates) {
        try {
            DocumentReference doctorRef = firestore.collection("doctors").document(uid);

            doctorRef.update(updates).get();

        } catch (Exception e) {
            log.error("Failed to update doctor profile for uid={}", uid, e);
            throw new RuntimeException("Failed to update doctor profile", e);
        }
    }

    /** Retrieves doctor profile */
    public doctorProfileResponseDto getDoctorProfile(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("doctors")
                    .document(uid)
                    .get()
                    .get();

            if (!snapshot.exists()) {
                throw new RuntimeException("Doctor not found");
            }

            // handling if no image exists
            String imagePath = snapshot.getString("profilePhotoURL");
            String imageUrl = null;
            if (imagePath != null && !imagePath.isBlank()) {
                imageUrl = imageStorageService.generateDownloadUrl(imagePath);
            }

            return doctorProfileResponseDto.builder()
                    .name(snapshot.getString("name"))
                    .email(snapshot.getString("email"))
                    .gender(snapshot.getString("gender"))
                    .areaOfKnowledge(snapshot.getString("areaOfKnowledge"))
                    .qualifications((getQualificationsStringList(snapshot, "qualifications")))
                    .yearsOfExperience(snapshot.getLong("yearsOfExperience") != null
                            ? snapshot.getLong("yearsOfExperience").intValue()
                            : null)
                    .profilePhotoURL(imageUrl)
                    .iban(snapshot.getString("iban"))
                    .scfhsNumber(snapshot.getString("scfhsNumber"))
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch doctor profile", e);
        }
    }

    /** Prepare qualifications as list for forntend */
    private List<String> getQualificationsStringList(DocumentSnapshot snapshot, String field) {
        Object value = snapshot.get(field);

        if (value == null) {
            return new ArrayList<>();
        }

        if (!(value instanceof List<?> rawList)) {
            throw new RuntimeException("Field '" + field + "' is not a list. Found: " + value.getClass());
        }

        List<String> result = new ArrayList<>();
        for (Object item : rawList) {
            result.add(String.valueOf(item));
        }

        return result;
    }

    /* handling doctor profile image */
    private String handleProfileImage(String oldImagePath, String newImagePath) {

        // convert "null" string → real null
        if ("null".equals(newImagePath)) {
            newImagePath = null;
        }

        // delete case
        if (newImagePath == null) {
            if (oldImagePath != null) {
                imageStorageService.deleteImage(oldImagePath);
            }
            return null;
        }

        // same image
        if (newImagePath.equals(oldImagePath)) {
            return oldImagePath;
        }

        // replace
        if (oldImagePath != null) {
            imageStorageService.deleteImage(oldImagePath);
        }

        return newImagePath;
    }

    /** Retrieves basic caregiver profile (name, email). */
    public caregiverProfileResponseDto getCaregiverProfile(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("caregivers")
                    .document(uid)
                    .get()
                    .get();

            if (!snapshot.exists()) {
                throw new RuntimeException("Caregiver not found");
            }

            return caregiverProfileResponseDto.builder()
                    .name(snapshot.getString("name"))
                    .email(snapshot.getString("email"))
                    .build();

        } catch (Exception e) {
            log.error("Failed to fetch caregiver profile for uid={}", uid, e);
            throw new RuntimeException("Failed to fetch caregiver profile", e);
        }
    }

    /** Updates caregiver name. */
    public void updateCaregiverName(String uid, String name) {

        if (name == null || name.trim().isEmpty()) {
            throw new RuntimeException("Name cannot be empty");
        }

        try {
            DocumentReference caregiverRef = firestore.collection("caregivers").document(uid);

            caregiverRef.update("name", name.trim()).get();

        } catch (Exception e) {
            log.error("Failed to update caregiver name for uid={}", uid, e);
            throw new RuntimeException("Failed to update caregiver name", e);
        }
    }

    /* Creates a new request for qualification changes to be reviewed by an admin */
    private void createQualificationEditRequest(String doctorId, List<String> oldQualifications,
            List<String> newQualifications) {
        try {
            Map<String, Object> request = new HashMap<>();
            request.put("doctorId", doctorId);
            request.put("oldQualifications", oldQualifications);
            request.put("newQualifications", newQualifications);
            request.put("createdAt", Timestamp.now());

            firestore.collection("qualificationEditRequests")
                    .add(request)
                    .get();

            log.info("Qualification edit request created for doctor={}", doctorId);

        } catch (Exception e) {
            log.error("Failed to create qualification edit request", e);
            throw new RuntimeException("Failed to create qualification edit request", e);
        }
    }

    private boolean hasPendingRequest(String doctorId) {
        try {
            return !firestore.collection("qualificationEditRequests")
                    .whereEqualTo("doctorId", doctorId)
                    .get()
                    .get()
                    .isEmpty();

        } catch (Exception e) {
            log.error("Failed to check pending requests for doctor={}", doctorId, e);
            throw new RuntimeException("Failed to check pending requests", e);
        }
    }

}
