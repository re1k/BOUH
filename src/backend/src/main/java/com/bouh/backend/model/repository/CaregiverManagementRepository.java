package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.CaregiverManagement;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Repository
public class CaregiverManagementRepository {
    private final Firestore firestore;

    public CaregiverManagementRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<CaregiverManagement> findAllCaregivers() throws ExecutionException, InterruptedException {
        List<CaregiverManagement> result = new ArrayList<>();

        var snapshot = firestore
                .collection("caregivers")
                .get()
                .get();

        for (QueryDocumentSnapshot doc : snapshot.getDocuments()) {
            result.add(mapToCaregiverInfo(doc));
        }

        return result;
    }

    private CaregiverManagement mapToCaregiverInfo(QueryDocumentSnapshot doc) {
        CaregiverManagement caregiver = new CaregiverManagement();
        caregiver.setUid(doc.getId());
        caregiver.setName(doc.getString("name"));
        caregiver.setEmail(doc.getString("email"));
        return caregiver;
    }
}
