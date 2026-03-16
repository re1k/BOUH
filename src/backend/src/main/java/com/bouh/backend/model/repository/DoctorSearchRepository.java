package com.bouh.backend.model.repository;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;
import com.google.cloud.firestore.Query;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Repository
public class DoctorSearchRepository {
    private final Firestore firestore;
    private static final int PAGE_SIZE = 20;

    public DoctorSearchRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<QueryDocumentSnapshot> getAllDoctors() throws ExecutionException, InterruptedException {
        QuerySnapshot snapshot = firestore.collection("doctors")
                .whereEqualTo("registrationStatus", "APPROVED")
                .get()
                .get();
        return snapshot.getDocuments();
    }

    public List<QueryDocumentSnapshot> getDoctorsByArea(String area)
            throws ExecutionException, InterruptedException {
        QuerySnapshot snapshot = firestore.collection("doctors")
                .whereEqualTo("registrationStatus", "APPROVED")
                .whereEqualTo("areaOfKnowledge", area)
                .orderBy("averageRating", Query.Direction.DESCENDING)
                .get()
                .get();
        return snapshot.getDocuments();
    }

    public List<QueryDocumentSnapshot> getTopRatedDoctors(String lastDoctorId)
            throws ExecutionException, InterruptedException {

        Query query = firestore.collection("doctors")
                .whereEqualTo("registrationStatus", "APPROVED")
                .orderBy("averageRating", Query.Direction.DESCENDING)
                .limit(PAGE_SIZE + 1); // fetch 21 to check if there are more

        // if cursor provided, fetch that doc first and use it as cursor
        if (lastDoctorId != null && !lastDoctorId.isEmpty()) {
            DocumentSnapshot lastDoc = firestore
                    .collection("doctors")
                    .document(lastDoctorId)
                    .get()
                    .get();
            query = query.startAfter(lastDoc);
        }

        return query.get().get().getDocuments();
    }
}
