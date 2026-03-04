package com.bouh.backend.model.repository;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Repository
public class childRepo {

    private final Firestore firestore;

    public childRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    /** Child name from subcollection or from caregiver doc "children" array/map. */
    public String findChildName(String caregiverId, String childId) throws ExecutionException, InterruptedException {
        DocumentSnapshot childDoc = firestore.collection("caregivers").document(caregiverId)
                .collection("children").document(childId).get().get();
        if (childDoc.exists()) {
            Object name = childDoc.get("name");
            if (name != null) return name.toString();
        }

        DocumentSnapshot cgDoc = firestore.collection("caregivers").document(caregiverId).get().get();
        if (!cgDoc.exists()) return null;
        Object children = cgDoc.get("children");
        Object item = null;
        if (children instanceof List) {
            List<?> list = (List<?>) children;
            int i = -1;
            try { i = Integer.parseInt(childId != null ? childId.trim() : ""); } catch (NumberFormatException ignored) {}
            if (i >= 0 && i < list.size()) item = list.get(i);
        } else if (children instanceof Map) {
            item = ((Map<?, ?>) children).get(childId);
        }
        if (item instanceof Map) {
            Object name = ((Map<?, ?>) item).get("name");
            return name != null ? name.toString() : null;
        }
        return null;
    }
}
