package com.bouh.backend.model.repository;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

@Repository
public class adminRepo {

    private static final Logger log = LoggerFactory.getLogger(adminRepo.class);

    private final Firestore firestore;

    public adminRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    public boolean isAdmin(String uid) {
        try {
            DocumentSnapshot snapshot = firestore
                    .collection("admins")
                    .document(uid)
                    .get()
                    .get();

            return snapshot.exists();

        } catch (Exception e) {
            log.error("Failed to check admin existence for uid={}", uid, e);
            throw new RuntimeException("Admin check failed", e);
        }
    }
}
