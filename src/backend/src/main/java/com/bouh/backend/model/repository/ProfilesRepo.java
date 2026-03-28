package com.bouh.backend.model.repository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Repository;

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
            return null; // don't delete if not sent

        List<String> result = qualifications.stream()
                .map(String::trim)
                .filter(q -> !q.isEmpty())
                .distinct()
                .limit(12)
                .toList();

        return result.isEmpty() ? null : result;
    }

    /** Updates editable doctor fields. */
    public void updateDoctor(String uid, doctorUpdateDto dto) {

        Map<String, Object> updates = new HashMap<>();

        // Editable fields only
        putIfNotNull(updates, "name", dto.getName());
        putIfNotNull(updates, "gender", dto.getGender());
        putIfNotNull(updates, "yearsOfExperience", dto.getYearsOfExperience());
        putIfNotNull(updates, "profilePhotoURL", dto.getProfilePhotoURL());
        putIfNotNull(updates, "iban", dto.getIban());

        // qualifications (cleaned)
        putIfNotNull(updates, "qualifications",
                cleanQualifications(dto.getQualifications()));

        if (updates.isEmpty()) {
            throw new RuntimeException("No fields to update");
        }

        updateDoctorProfile(uid, updates);
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

    /** Retrieves basic caregiver profile (name, email). */
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

            return doctorProfileResponseDto.builder()
                    .name(snapshot.getString("name"))
                    .email(snapshot.getString("email"))
                    .gender(snapshot.getString("gender"))
                    .areaOfKnowledge(snapshot.getString("areaOfKnowledge"))
                    .qualifications((List<String>) snapshot.get("qualifications"))
                    .yearsOfExperience(snapshot.getLong("yearsOfExperience") != null
                            ? snapshot.getLong("yearsOfExperience").intValue()
                            : null)
                    .profilePhotoURL(imageStorageService.generateDownloadUrl(snapshot.getString("profilePhotoURL")) )
                    .iban(snapshot.getString("iban"))
                    .scfhsNumber(snapshot.getString("scfhsNumber"))
                    .build();

        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch doctor profile", e);
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
}