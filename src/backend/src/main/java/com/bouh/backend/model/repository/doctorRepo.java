package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.doctorDto;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Repository;

import java.util.concurrent.ExecutionException;


@Repository
public class doctorRepo {

    private final Firestore firestore;

    public doctorRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Read doctor document from doctors/{doctorId}. Returns name, areaOfKnowledge, profilePhotoURL for response DTO.
     */
    public doctorDto findById(String doctorId) throws ExecutionException, InterruptedException {
        DocumentReference ref = firestore.collection("doctors").document(doctorId);
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

            Double avg = doc.getDouble("averageRating");
            dto.setAverageRating(avg == null ? 0.0 : avg);

            dto.setProfilePhotoURL(getString(doc, "profilePhotoURL"));

            result.add(dto);
        }

        return result;
    }

    private static String getString(DocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        return v == null ? null : v.toString();
    }
}
