package com.bouh.backend.service.appointments;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.Dto.timeSlotDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.childRepo;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

/**
 * Service that builds upcoming appointments for a caregiver.
 * Caller: appointmentsController. Uses appointmentRepo, DoctorRepo, ChildRepo
 * to read Firestore and build response DTOs.
 */
@Service
public class AppointmentsService {

    private final AppointmentRepo appointmentRepo;
    private final doctorRepo doctorRepo;
    private final childRepo childRepo;

    public AppointmentsService(AppointmentRepo appointmentRepo, doctorRepo doctorRepo, childRepo childRepo) {
        this.appointmentRepo = appointmentRepo;
        this.doctorRepo = doctorRepo;
        this.childRepo = childRepo;
    }

    /**
     * Get upcoming appointments for the given caregiverId: query appointments with
     * date >= today (no status filter).
     * status in DB is for attendance only (حضر / لم يحضر). Resolve doctor, child
     * name, time slot for each.
     */
    public List<upcomingAppointmentDto> getUpcomingAppointments(String caregiverId)
            throws ExecutionException, InterruptedException {
        List<appointmentDto> docs = appointmentRepo.findByCaregiverIdAndDateFromToday(caregiverId);
        List<upcomingAppointmentDto> result = new ArrayList<>();
        for (appointmentDto doc : docs) {
            // status is for attendance only (حضر / لم يحضر), not for filtering upcoming —
            // show all with date >= today
            doctorDto doctor = doctorRepo.findById(doc.getDoctorId());
            String childName = childRepo.findChildName(doc.getCaregiverId(), doc.getChildId());
            timeSlotDto slot = doctorRepo.findTimeSlot(doc.getDoctorId(), doc.getTimeSlotId());

            upcomingAppointmentDto dto = new upcomingAppointmentDto();
            dto.setAppointmentId(doc.getAppointmentId());
            dto.setDate(doc.getDate());
            dto.setStartTime(slot != null ? slot.getStartTime() : null);
            dto.setEndTime(slot != null ? slot.getEndTime() : null);
            dto.setDoctorName(doctor != null ? doctor.getName() : null);
            dto.setDoctorAreaOfKnowledge(doctor != null ? doctor.getAreaOfKnowledge() : null);
            dto.setDoctorProfilePhotoURL(doctor != null ? doctor.getProfilePhotoURL() : null);
            dto.setChildName(childName);
            dto.setStatus(doc.getStatus());
            dto.setMeetingLink(doc.getMeetingLink());
            dto.setPaymentIntentId(doc.getPaymentIntentId());
            result.add(dto);
        }
        return result;
    }
}
