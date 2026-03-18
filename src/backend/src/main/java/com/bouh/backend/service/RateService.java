package com.bouh.backend.service;
import com.bouh.backend.model.Dto.RateDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;

@Service
public class RateService {

    private final doctorRepo doctorRepo;
    private final AppointmentRepo appointmentRepo;

    public RateService(doctorRepo doctorRepo, AppointmentRepo appointmentRepo ) {
        this.doctorRepo = doctorRepo;
        this.appointmentRepo = appointmentRepo;
    }

    // add a rate
    public void rateDoctor(RateDto dto) throws Exception {
        doctorRepo.addRating(dto.getDoctorId(), dto.getRating());
        appointmentRepo.updateRating(dto.getAppointmentId());
    }
}