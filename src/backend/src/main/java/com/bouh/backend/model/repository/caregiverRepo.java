package com.bouh.backend.model.repository;
import com.bouh.backend.model.Dto.caregiverDto;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

@Slf4j //for log debugging
@Repository
public class caregiverRepo {

    //springBoot on config it will inject the globally created FireStore bean (in Config File) into this Repo instance of fireStore
    private final Firestore firestore;
    public caregiverRepo(Firestore firestore) {
        this.firestore = firestore; //set the instance so this repo use it
    }

    public void createCaregiver(String uid, caregiverDto caregiver) {
        try {
            firestore
                    .collection("caregivers")
                    .document(uid)
                    .set(caregiver)
                    .get(); // wait for completion (important for error visibility)

        } catch (Exception e) {
            // Log with context (VERY important for debugging)
            log.error("Failed to create caregiver profile for uid={}", uid, e);

            // Re-throw so higher layers can react
            throw new RuntimeException("Failed to create caregiver profile", e);
        }
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
}
