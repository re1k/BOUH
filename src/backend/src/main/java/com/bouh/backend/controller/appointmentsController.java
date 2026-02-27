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

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * REST controller for appointment endpoints.
 */
@RestController
@RequestMapping("/api/appointments")
public class appointmentsController {

    private final AppointmentsService appointmentsService;

    public appointmentsController(AppointmentsService appointmentsService) {
        this.appointmentsService = appointmentsService;

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

    /**
     * GET /api/appointments/previous/{caregiverId} — returns list of previous
     * booked appointments.
     */
    @GetMapping(value = "/previous/{caregiverId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getPrevious(@PathVariable String caregiverId)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getPreviousAppointments(caregiverId);
        return ResponseEntity.ok(list);
    }
@DeleteMapping(value = "/{appointmentId}", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<Map<String, Object>> cancel(@PathVariable String appointmentId)
        throws ExecutionException, InterruptedException {

    appointmentsService.cancelAppointment(appointmentId);

    Map<String, Object> res = new HashMap<>();
    res.put("success", true);
    res.put("message", "Appointment cancelled successfully");
    res.put("appointmentId", appointmentId);

    return ResponseEntity.ok(res);
}
}
