package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.DoctorManagement;
import com.bouh.backend.model.Dto.DoctorStatsDTO;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Repository;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.QuerySnapshot;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import com.bouh.backend.service.GcsImageService;

import com.bouh.backend.model.Dto.Qualificationrequestdto;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;

@Repository
public class DoctorManagementRepository {

    private final Firestore firestore;
    private final GcsImageService gcsImageService;

    public DoctorManagementRepository(Firestore firestore, GcsImageService gcsImageService) {
        this.firestore = firestore;
        this.gcsImageService = gcsImageService;
    }

    public List<DoctorManagement> findDoctorsByStatus(String status) throws ExecutionException, InterruptedException {
        var snapshot = firestore
                .collection("doctors")
                .whereEqualTo("registrationStatus", status)
                .whereEqualTo("isActivated", true)
                .get()
                .get();

        List<DoctorManagement> result = new ArrayList<>();
        List<QueryDocumentSnapshot> docs = snapshot.getDocuments();

        // Fire all signed URL requests in parallel
        List<ApiFuture<String>> urlFutures = new ArrayList<>();
        List<String> profilePaths = new ArrayList<>();

        for (QueryDocumentSnapshot doc : docs) {
            String profilePath = doc.getString("profilePhotoURL");
            profilePaths.add(profilePath);
        }

        // Map doctors with parallel URL generation
        for (int i = 0; i < docs.size(); i++) {
            QueryDocumentSnapshot doc = docs.get(i);
            String profilePath = profilePaths.get(i);

            DoctorManagement doctor = mapToDoctor(doc);

            try {
                doctor.setProfilePhotoURL(
                        profilePath != null && !profilePath.isBlank()
                                ? gcsImageService.generateDownloadUrl(profilePath)
                                : null);
            } catch (Exception e) {
                doctor.setProfilePhotoURL(null);
            }

            result.add(doctor);
        }

        return result;
    }

    public DoctorStatsDTO getDoctorStats() throws ExecutionException, InterruptedException {
        // Fire all 3 queries at the same time
        ApiFuture<QuerySnapshot> pendingFuture = firestore
                .collection("doctors")
                .whereEqualTo("registrationStatus", "PENDING")
                .get();

        ApiFuture<QuerySnapshot> acceptedFuture = firestore
                .collection("doctors")
                .whereEqualTo("registrationStatus", "APPROVED")
                .whereEqualTo("isActivated", true)
                .get();

        ApiFuture<QuerySnapshot> rejectedFuture = firestore
                .collection("doctors")
                .whereEqualTo("registrationStatus", "REJECTED")
                .get();

        // Now wait for all 3 together
        long pending = pendingFuture.get().size();
        long accepted = acceptedFuture.get().size();
        long rejected = rejectedFuture.get().size();

        return new DoctorStatsDTO(pending, accepted, rejected);
    }

    public String[] getDoctorEmailAndName(String uid) throws ExecutionException, InterruptedException {
        var doc = firestore.collection("doctors").document(uid).get().get();
        if (!doc.exists())
            return null;

        Boolean isActivated = doc.getBoolean("isActivated");
        if (isActivated == null || !isActivated)
            return null;
        return new String[] { doc.getString("email"), doc.getString("name") };
    }

    public void updateRegistrationStatus(String uid, String status) throws ExecutionException, InterruptedException {
        firestore.collection("doctors")
                .document(uid)
                .update("registrationStatus", status)
                .get();
    }

    private DoctorManagement mapToDoctor(QueryDocumentSnapshot doc) {
        DoctorManagement doctor = new DoctorManagement();
        doctor.setUid(doc.getId());
        doctor.setName(doc.getString("name"));
        doctor.setEmail(doc.getString("email"));
        doctor.setAreaOfKnowledge(doc.getString("areaOfKnowledge"));
        doctor.setIban(doc.getString("iban"));
        doctor.setScfhsNumber(doc.getString("scfhsNumber"));

        Long years = doc.getLong("yearsOfExperience");
        doctor.setYearsOfExperience(years != null ? years.intValue() : 0);

        List<String> qualifications = (List<String>) doc.get("qualifications");
        doctor.setQualifications(qualifications != null ? qualifications : new ArrayList<>());

        return doctor;
    }

    public void applyQualificationUpdate(String doctorId, String requestId) {
        try {
            // Reference to doctor document
            DocumentReference doctorRef = firestore.collection("doctors").document(doctorId);

            // Reference to the qualification edit request
            DocumentReference requestRef = firestore.collection("qualificationEditRequests").document(requestId);

            // Fetch the request document
            DocumentSnapshot requestSnap = requestRef.get().get();

            // Validate that the request exists
            if (!requestSnap.exists()) {
                throw new RuntimeException("Request not found");
            }

            // Extract the new qualifications from the request
            List<String> newQualifications = (List<String>) requestSnap.get("newQualifications");

            // If null, initialize as empty list to avoid errors
            if (newQualifications == null) {
                newQualifications = new ArrayList<>();
            }

            // Replace the doctor's qualifications with the new list
            doctorRef.update("qualifications", newQualifications).get();

        } catch (Exception e) {
            throw new RuntimeException("Failed to update qualifications", e);
        }
    }

    public List<Qualificationrequestdto> getPendingQualificationRequests()
            throws ExecutionException, InterruptedException {

        var snapshot = firestore
                .collection("qualificationEditRequests")
                .get()
                .get();

        List<Qualificationrequestdto> result = new ArrayList<>();

        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            String doctorId = doc.getString("doctorId");
            if (doctorId == null)
                continue;

            // Fetch doctor info
            DocumentSnapshot doctorSnap = firestore
                    .collection("doctors")
                    .document(doctorId)
                    .get()
                    .get();

            if (!doctorSnap.exists())
                continue;
            Boolean isActivated = doctorSnap.getBoolean("isActivated");
            if (isActivated == null || !isActivated)
                continue;

            String name = doctorSnap.getString("name");
            String email = doctorSnap.getString("email");
            String profilePath = doctorSnap.getString("profilePhotoURL");

            // Generate signed URL for profile photo
            String photoUrl = null;
            try {
                if (profilePath != null && !profilePath.isBlank()) {
                    photoUrl = gcsImageService.generateDownloadUrl(profilePath);
                }
            } catch (Exception e) {
                photoUrl = null;
            }

            List<String> oldQualifications = (List<String>) doc.get("oldQualifications");
            List<String> newQualifications = (List<String>) doc.get("newQualifications");

            Qualificationrequestdto dto = new Qualificationrequestdto(
                    doc.getId(),
                    doctorId,
                    name,
                    email,
                    photoUrl,
                    oldQualifications != null ? oldQualifications : new ArrayList<>(),
                    newQualifications != null ? newQualifications : new ArrayList<>());

            result.add(dto);
        }

        return result;
    }

    public void deleteQualificationRequest(String requestId)
            throws ExecutionException, InterruptedException {
        firestore.collection("qualificationEditRequests")
                .document(requestId)
                .delete()
                .get();
    }

    public String getDoctorIdFromRequest(String requestId)
            throws ExecutionException, InterruptedException {
        DocumentSnapshot snap = firestore
                .collection("qualificationEditRequests")
                .document(requestId)
                .get()
                .get();
        if (!snap.exists())
            throw new RuntimeException("Request not found: " + requestId);
        return snap.getString("doctorId");
    }
}
