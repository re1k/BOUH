package com.bouh.backend.model.repository;

import com.bouh.backend.model.Dto.childDto;
import com.google.cloud.firestore.*;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Repository
public class childrenRepo {

    private final Firestore firestore;

    public childrenRepo(Firestore firestore) {
        this.firestore = firestore;
    }

    private CollectionReference childrenCollection(String caregiverId) {
        return firestore.collection("caregivers")
                .document(caregiverId)
                .collection("children");
    }

    public List<childDto> getChildren(String caregiverId) throws ExecutionException, InterruptedException {
        var result = new ArrayList<childDto>();

        var snap = childrenCollection(caregiverId).get().get();
        for (DocumentSnapshot doc : snap.getDocuments()) {
            var dto = new childDto();
            dto.setChildID(doc.getId());
            dto.setName(getString(doc, "name"));
            dto.setDateOfBirth(getLocalDate(doc, "dateOfBirth")); //  LocalDate
            dto.setGender(getString(doc, "gender"));
            result.add(dto);
        }
        return result;
    }

    public int countChildren(String caregiverId) throws ExecutionException, InterruptedException {
        return childrenCollection(caregiverId).get().get().size();
    }

    public childDto getChildById(String caregiverId, String childId) throws ExecutionException, InterruptedException {
        var ref = childrenCollection(caregiverId).document(childId);
        var doc = ref.get().get();
        if (doc == null || !doc.exists()) return null;

        var dto = new childDto();
        dto.setChildID(childId);
        dto.setName(getString(doc, "name"));
        dto.setDateOfBirth(getLocalDate(doc, "dateOfBirth")); //  LocalDate
        dto.setGender(getString(doc, "gender"));
        return dto;
    }

  
    // Adds a new child
    public childDto addChild(String caregiverId, String name, String dateOfBirth, String gender)
            throws ExecutionException, InterruptedException {

        DocumentReference newRef = childrenCollection(caregiverId).document(); // auto ID

        // Validate/normalize DOB (expects yyyy-MM-dd), If invalid store null
        LocalDate dob = parseLocalDate(dateOfBirth);

        newRef.set(new java.util.HashMap<String, Object>() {{
            put("name", name);
            put("dateOfBirth", dob == null ? null : dob.toString()); // stored as ISO string
            put("gender", gender);
            put("createdAt", FieldValue.serverTimestamp());
            put("updatedAt", FieldValue.serverTimestamp());
        }}).get();

        return getChildById(caregiverId, newRef.getId());
    }

    /**
     * Updates an existing child.
     * If updates contains "dateOfBirth" as String, we normalize it to (yyyy-MM-dd).
     */
    public childDto updateChild(String caregiverId, String childId, Map<String, Object> updates)
            throws ExecutionException, InterruptedException {

        var ref = childrenCollection(caregiverId).document(childId);
        var doc = ref.get().get();
        if (doc == null || !doc.exists()) return null;

        // Normalize dateOfBirth if present
        if (updates.containsKey("dateOfBirth")) {
            Object dobRaw = updates.get("dateOfBirth");

            if (dobRaw == null) {
                updates.put("dateOfBirth", null);
            } else if (dobRaw instanceof LocalDate) {
                updates.put("dateOfBirth", ((LocalDate) dobRaw).toString());
            } else {
                // assume string
                LocalDate dob = parseLocalDate(dobRaw.toString());
                updates.put("dateOfBirth", dob == null ? null : dob.toString());
            }
        }

        updates.put("updatedAt", FieldValue.serverTimestamp());
        ref.update(updates).get();

        return getChildById(caregiverId, childId);
    }

    public boolean deleteChild(String caregiverId, String childId) throws ExecutionException, InterruptedException {
        var ref = childrenCollection(caregiverId).document(childId);
        var doc = ref.get().get();
        if (doc == null || !doc.exists()) return false;

        ref.delete().get();
        return true;
    }

    /**  helper to read strings from Firestore. */
    private static String getString(DocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        return v == null ? null : v.toString();
    }

    /**
     * Reads a LocalDate from Firestore.
     * Expected storage format: "yyyy-MM-dd" 
     */
    private static LocalDate getLocalDate(DocumentSnapshot doc, String field) {
        Object v = doc.get(field);
        if (v == null) return null;
        return parseLocalDate(v.toString());
    }

    
    private static LocalDate parseLocalDate(String value) {
        if (value == null) return null;
        String s = value.trim();
        if (s.isEmpty()) return null;

        try {
            return LocalDate.parse(s); 
        } catch (Exception e) {
            return null;
        }
    }
}
// REEM 
// package com.bouh.backend.model.repository;

// import com.bouh.backend.model.Dto.childDto;
// import com.google.cloud.firestore.*;
// import org.springframework.stereotype.Repository;

// import java.time.LocalDate;
// import java.util.ArrayList;
// import java.util.List;
// import java.util.Map;
// import java.util.concurrent.ExecutionException;

// @Repository
// public class childrenRepo {

//     private final Firestore firestore;

//     public childrenRepo(Firestore firestore) {
//         this.firestore = firestore;
//     }

//     /**
//      * Reference to: caregivers/{caregiverId}/children
//      */
//     private CollectionReference childrenCollection(String caregiverId) {
//         return firestore.collection("caregivers")
//                 .document(caregiverId)
//                 .collection("children");
//     }

//     /**
//      * Returns all children for a caregiver
//      */
//     public List<childDto> getChildren(String caregiverId) throws ExecutionException, InterruptedException {
//         var result = new ArrayList<childDto>();

//         var snap = childrenCollection(caregiverId).get().get();
//         for (DocumentSnapshot doc : snap.getDocuments()) {
//             var dto = new childDto();
//             dto.setChildID(doc.getId());
//             dto.setName(getString(doc, "name"));
//             dto.setDateOfBirth(getLocalDate(doc, "dateOfBirth"));
//             dto.setGender(getString(doc, "gender"));
//             result.add(dto);
//         }
//         return result;
//     }

//     public int countChildren(String caregiverId) throws ExecutionException, InterruptedException {
//         return childrenCollection(caregiverId).get().get().size();
//     }

//     public childDto getChildById(String caregiverId, String childId) throws ExecutionException, InterruptedException {
//         var ref = childrenCollection(caregiverId).document(childId);
//         var doc = ref.get().get();
//         if (doc == null || !doc.exists()) return null;

//         var dto = new childDto();
//         dto.setChildID(childId);
//         dto.setName(getString(doc, "name"));
//         dto.setDateOfBirth(getLocalDate(doc, "dateOfBirth"));
//         dto.setGender(getString(doc, "gender"));
//         return dto;
//     }

//     /**
//      * Adds a new child.
//      * We store dateOfBirth in Firestore as ISO string (yyyy-MM-dd) for consistency,
//      * but the DTO exposes it as LocalDate.
//      */
//     public childDto addChild(String caregiverId, String name, String dateOfBirth, String gender)
//             throws ExecutionException, InterruptedException {

//         DocumentReference newRef = childrenCollection(caregiverId).document(); // auto ID

//         LocalDate dob = parseLocalDate(dateOfBirth);

//         newRef.set(new java.util.HashMap<String, Object>() {{
//             put("name", name);
//             put("dateOfBirth", dob == null ? null : dob.toString());
//             put("gender", gender);
//             put("createdAt", FieldValue.serverTimestamp());
//             put("updatedAt", FieldValue.serverTimestamp());
//         }}).get();

//         return getChildById(caregiverId, newRef.getId());
//     }

//     /**
//      * Updates an existing child.
//      * If dateOfBirth is provided as String or LocalDate, we normalize to ISO string in Firestore.
//      */
//     public childDto updateChild(String caregiverId, String childId, Map<String, Object> updates)
//             throws ExecutionException, InterruptedException {

//         var ref = childrenCollection(caregiverId).document(childId);
//         var doc = ref.get().get();
//         if (doc == null || !doc.exists()) return null;

//         // Normalize dateOfBirth if present
//         if (updates.containsKey("dateOfBirth")) {
//             Object dobRaw = updates.get("dateOfBirth");

//             if (dobRaw == null) {
//                 updates.put("dateOfBirth", null);
//             } else if (dobRaw instanceof LocalDate) {
//                 updates.put("dateOfBirth", ((LocalDate) dobRaw).toString());
//             } else {
//                 LocalDate dob = parseLocalDate(dobRaw.toString());
//                 updates.put("dateOfBirth", dob == null ? null : dob.toString());
//             }
//         }

//         updates.put("updatedAt", FieldValue.serverTimestamp());
//         ref.update(updates).get();

//         return getChildById(caregiverId, childId);
//     }

//     public boolean deleteChild(String caregiverId, String childId) throws ExecutionException, InterruptedException {
//         var ref = childrenCollection(caregiverId).document(childId);
//         var doc = ref.get().get();
//         if (doc == null || !doc.exists()) return false;

//         ref.delete().get();
//         return true;
//     }

//     /**
//      * Finds a child's name.
//      *
//      * 1) Current structure: caregivers/{caregiverId}/children/{childId}
//      * 2) Legacy fallback: caregivers/{caregiverId}.children field (List or Map)
//      *
//      * NOTE: The List fallback assumes childId can be parsed as an index.
//      */
//     public String findChildName(String caregiverId, String childId) throws ExecutionException, InterruptedException {

//         // 1) Try the current structure (subcollection)
//         DocumentSnapshot childDoc = childrenCollection(caregiverId)
//                 .document(childId)
//                 .get()
//                 .get();

//         if (childDoc.exists()) {
//             Object name = childDoc.get("name");
//             if (name != null) return name.toString();
//         }

//         // 2) Fallback: legacy structure in caregiver document
//         DocumentSnapshot cgDoc = firestore.collection("caregivers")
//                 .document(caregiverId)
//                 .get()
//                 .get();

//         if (!cgDoc.exists()) return null;

//         Object children = cgDoc.get("children");
//         Object item = null;

//         if (children instanceof List) {
//             List<?> list = (List<?>) children;
//             int i = -1;
//             try {
//                 i = Integer.parseInt(childId != null ? childId.trim() : "");
//             } catch (NumberFormatException ignored) {}

//             if (i >= 0 && i < list.size()) item = list.get(i);

//         } else if (children instanceof Map) {
//             item = ((Map<?, ?>) children).get(childId);
//         }

//         if (item instanceof Map) {
//             Object name = ((Map<?, ?>) item).get("name");
//             return name != null ? name.toString() : null;
//         }

//         return null;
//     }

//     /** Safe helper to read strings from Firestore. */
//     private static String getString(DocumentSnapshot doc, String field) {
//         Object v = doc.get(field);
//         return v == null ? null : v.toString();
//     }

//     /**
//      * Reads a LocalDate from Firestore (expected ISO "yyyy-MM-dd").
//      * Returns null if missing or invalid.
//      */
//     private static LocalDate getLocalDate(DocumentSnapshot doc, String field) {
//         Object v = doc.get(field);
//         if (v == null) return null;
//         return parseLocalDate(v.toString());
//     }

//     /**
//      * Parses ISO date string (yyyy-MM-dd). Returns null if invalid.
//      */
//     private static LocalDate parseLocalDate(String value) {
//         if (value == null) return null;
//         String s = value.trim();
//         if (s.isEmpty()) return null;

//         try {
//             return LocalDate.parse(s);
//         } catch (Exception e) {
//             return null;
//         }
//     }
// }