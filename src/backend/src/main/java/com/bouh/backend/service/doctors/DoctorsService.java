package com.bouh.backend.service.doctors;

import com.bouh.backend.model.Dto.DoctorDetailsDto;
import com.bouh.backend.model.Dto.DoctorScheduleDto;
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

    // existing (list page)
    public List<DoctorSummaryDto> getDoctorsForCaregiverList()
            throws ExecutionException, InterruptedException {
        return doctorRepo.getDoctorsForCaregiverList();
    }

    //  doctor details page
    public DoctorDetailsDto getDoctorDetails(String doctorId) throws Exception {
        return doctorRepo.getDoctorDetails(doctorId);
    }

    //  doctor schedule for booking
    public DoctorScheduleDto getDoctorScheduleByDate(String doctorId, String date) throws Exception {
        return doctorRepo.getDoctorScheduleByDate(doctorId, date);
    }
}