package com.bouh.backend.service.doctors;

import com.bouh.backend.model.Dto.DoctorSummaryDto;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class DoctorsService {

    private final doctorRepo doctorRepo;

    public DoctorsService(doctorRepo doctorRepo) {
        this.doctorRepo = doctorRepo;
    }

    public List<DoctorSummaryDto> getDoctorsForCaregiverList() throws ExecutionException, InterruptedException {
        return doctorRepo.getDoctorsForCaregiverList();
    }
}