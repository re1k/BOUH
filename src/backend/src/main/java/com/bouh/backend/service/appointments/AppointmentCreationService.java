package com.bouh.backend.service.appointments;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import org.springframework.stereotype.Service;

@Service
public class AppointmentCreationService {
    private final AppointmentRepo appointmentRepository;

    public AppointmentCreationService(AppointmentRepo appointmentRepository) {
        this.appointmentRepository = appointmentRepository;
    }

    public String create(appointmentDto dto) {

        if (dto.getStatus() == null || dto.getStatus().isBlank()) {
            dto.setStatus("ABSENT");
        }

        return appointmentRepository.save(dto);
    }

    public void delete(String appointmentID) {
        appointmentRepository.deleteById(appointmentID);
    }

}
