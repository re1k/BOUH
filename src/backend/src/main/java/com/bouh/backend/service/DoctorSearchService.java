package com.bouh.backend.service;

import com.bouh.backend.model.Dto.DoctorPageDTO;
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
    private final GcsImageService gcsImageService;
    private static final int PAGE_SIZE = 20;

    public DoctorSearchService(DoctorSearchRepository doctorSearchRepository, GcsImageService gcsImageService) {
        this.doctorSearchRepository = doctorSearchRepository;
        this.gcsImageService = gcsImageService;
    }

    public List<DoctorSearchDTO> searchByName(String name)
            throws ExecutionException, InterruptedException {
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
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public List<DoctorSearchDTO> filterByAreaOfKnowledge(String area)
            throws ExecutionException, InterruptedException {
        List<QueryDocumentSnapshot> documents = doctorSearchRepository.getDoctorsByArea(area);
        return documents.stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public DoctorPageDTO getTopRatedDoctors(String lastDoctorId)
            throws ExecutionException, InterruptedException {

        List<QueryDocumentSnapshot> documents = doctorSearchRepository
                .getTopRatedDoctors(lastDoctorId);

        // we fetched PAGE_SIZE + 1 to check if there are more
        boolean hasMore = documents.size() > PAGE_SIZE;

        // only return PAGE_SIZE doctors
        List<DoctorSearchDTO> doctors = documents.stream()
                .limit(PAGE_SIZE)
                .map(this::toDTO)
                .collect(Collectors.toList());

        return new DoctorPageDTO(doctors, hasMore);
    }

    // reusable mapping method — no duplication
    private DoctorSearchDTO toDTO(QueryDocumentSnapshot doc) {
        String profilePath = doc.getString("profilePhotoURL");
        String photoUrl = null;
        try {
            photoUrl = profilePath != null && !profilePath.isBlank()
                    ? gcsImageService.generateDownloadUrl(profilePath)
                    : null;
        } catch (Exception e) {
            photoUrl = null;
        }

        return new DoctorSearchDTO(
                doc.getId(),
                doc.getString("name"),
                doc.getString("areaOfKnowledge"),
                doc.getDouble("averageRating") != null ? doc.getDouble("averageRating") : 0.0,
                photoUrl);
    }
}