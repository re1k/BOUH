package com.bouh.backend.model.repository;

import com.google.cloud.firestore.CollectionReference;
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

    public DoctorSearchRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<QueryDocumentSnapshot> getAllDoctors() throws ExecutionException, InterruptedException {
        CollectionReference doctors = firestore.collection("doctors");
        QuerySnapshot snapshot = doctors.get().get();
        return snapshot.getDocuments();
    }

    public List<QueryDocumentSnapshot> getTopRatedDoctors() throws ExecutionException, InterruptedException {
        CollectionReference doctors = firestore.collection("doctors");
        QuerySnapshot snapshot = doctors
                .orderBy("rating", Query.Direction.DESCENDING)
                .limit(10)
                .get()
                .get();
        return snapshot.getDocuments();
    }
}
