package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.service.appointments.AppointmentsService;

import jakarta.validation.Valid;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.bouh.backend.service.appointments.AppointmentCreationService;

import java.util.List;
import java.util.concurrent.ExecutionException;

/**
 * REST controller for appointment endpoints.
 */
@RestController
@RequestMapping("/api/appointments")
public class appointmentsController {

    private final AppointmentsService appointmentsService;
    private final AppointmentCreationService appointmentCreationService;

    public appointmentsController(AppointmentsService appointmentsService,
            AppointmentCreationService appointmentCreationService) {
        this.appointmentsService = appointmentsService;
        this.appointmentCreationService = appointmentCreationService;

    }

    /**
     * GET /api/appointments/upcoming/{caregiverId} — returns list of upcoming
     * booked appointments for the caregiver.
     * Response: ResponseEntity.ok(List of upcomingAppointmentDto) as raw JSON.
     */
    @GetMapping(value = "/upcoming/{caregiverId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getUpcoming(@PathVariable String caregiverId)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getUpcomingAppointments(caregiverId);
        return ResponseEntity.ok(list);
    }

    @PostMapping
    public ResponseEntity<String> create(@Valid @RequestBody appointmentDto dto) {
        String id = appointmentCreationService.create(dto);
        return ResponseEntity.ok(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        appointmentCreationService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
