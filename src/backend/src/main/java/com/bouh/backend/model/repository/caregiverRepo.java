package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.Dto.childDto;
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.*;
import com.google.firebase.auth.FirebaseAuth;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.HashMap;
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

    public caregiverRepo(Firestore firestore) {
        this.firestore = firestore; // set the instance so this repo use it
    }

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

    /**
     * Returns the caregiver display name for doctor appointment views. Null if not found.
     */
    public String findNameByUid(String uid) throws ExecutionException, InterruptedException {
        if (uid == null || uid.isBlank()) return null;
        DocumentSnapshot snapshot = firestore.collection("caregivers").document(uid).get().get();
        if (!snapshot.exists()) return null;
        Object name = snapshot.get("name");
        return name != null ? name.toString() : null;
    }

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

    public void deleteCaregiver(String uid) {
        try {
            DocumentReference caregiverRef = firestore.collection("caregivers").document(uid);

            deleteAccountAppointments(uid);
            // to delete the collection and all it subCollectins
            firestore.recursiveDelete(caregiverRef).get();
            // delete Firebase Authentication account
            FirebaseAuth.getInstance().deleteUser(uid);

        } catch (Exception e) {
            log.error("Failed to delete caregiver account for uid={}", uid, e);
            throw new RuntimeException("Failed to delete caregiver account", e);
        }
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

    private void deleteAccountAppointments(String uid) throws Exception {

        ApiFuture<QuerySnapshot> future = firestore.collection("appointments")
                .whereEqualTo("caregiverId", uid)
                .get();

        List<QueryDocumentSnapshot> documents = future.get().getDocuments();

        for (QueryDocumentSnapshot doc : documents) {
            doc.getReference().delete().get();
        }
    }
}