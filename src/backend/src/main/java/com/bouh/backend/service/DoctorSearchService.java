package com.bouh.backend.service;

import com.bouh.backend.model.Dto.DoctorSearchDTO;
import com.bouh.backend.model.repository.DoctorSearchRepository;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Service
public class DoctorSearchService {

    private final DoctorSearchRepository doctorSearchRepository;

    public DoctorSearchService(DoctorSearchRepository doctorSearchRepository) {
        this.doctorSearchRepository = doctorSearchRepository;
    }

    public List<DoctorSearchDTO> searchByName(String name, String uid) throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> documents = doctorSearchRepository.getAllDoctors();

        return documents.stream()
                .filter(doc -> {
                    String docName = doc.getString("name");
                    if (docName == null)
                        return false;
                    String[] words = name.toLowerCase().split("\\s+");
                    for (String word : words) {
                        if (docName.toLowerCase().contains(word))
                            return true;
                    }
                    return false;
                })
                .map(doc -> new DoctorSearchDTO(
                        doc.getId(),
                        doc.getString("name"),
                        doc.getString("areaOfKnowledge"),
                        doc.getDouble("rating") != null ? doc.getDouble("rating") : 0.0,
                        doc.getString("profilePhotoURL") != null ? doc.getString("profilePhotoURL") : ""))
                .collect(Collectors.toList());
    }

    public List<DoctorSearchDTO> getTopRatedDoctors(String uid) throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> documents = doctorSearchRepository.getTopRatedDoctors();

        return documents.stream()
                .map(doc -> new DoctorSearchDTO(
                        doc.getId(),
                        doc.getString("name"),
                        doc.getString("areaOfKnowledge"),
                        doc.getDouble("rating") != null ? doc.getDouble("rating") : 0.0,
                        doc.getString("profilePhotoURL") != null ? doc.getString("profilePhotoURL") : ""))
                .collect(Collectors.toList());
    }
}
