package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.service.appointments.AppointmentsService;
import com.bouh.backend.model.Dto.appointmentCreateRequestDto;
import jakarta.validation.Valid;
import com.bouh.backend.model.Dto.Meeting.JoinMeetingResponseDto;
import com.bouh.backend.service.appointments.AgoraMeetingService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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
    private final AgoraMeetingService agoraMeetingService;

    public appointmentsController(
        AppointmentsService appointmentsService,
        AgoraMeetingService agoraMeetingService) {
    this.appointmentsService = appointmentsService;
    this.agoraMeetingService = agoraMeetingService;
}

    /**
     * GET /api/appointments/upcoming/{caregiverId} — returns list of upcoming
     * booked appointments for the caregiver.
     */
    @GetMapping(value = "/upcoming/{caregiverId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getUpcoming(
            @PathVariable String caregiverId,
            @AuthenticationPrincipal String firebaseDocUID)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getUpcomingAppointments(firebaseDocUID);
        return ResponseEntity.ok(list);
    }

    /**
     * GET /api/appointments/previous/{caregiverId} — returns list of previous
     * booked appointments.
     */
    @GetMapping(value = "/previous/{caregiverId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getPrevious(
            @PathVariable String caregiverId,
            @AuthenticationPrincipal String firebaseDocUID)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getPreviousAppointments(firebaseDocUID);
        return ResponseEntity.ok(list);
    }

    /**
     * GET /api/appointments/upcoming/doctor/{doctorId} — upcoming appointments for doctor view. 
     */
    @GetMapping(value = "/upcoming/doctor/{doctorId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getUpcomingByDoctor(
            @PathVariable String doctorId,
            @AuthenticationPrincipal String firebaseDocUID)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getUpcomingAppointmentsByDoctor(firebaseDocUID);
        return ResponseEntity.ok(list);
    }

    /**
     * GET /api/appointments/previous/doctor/{doctorId} — previous appointments for doctor view.
     */
    @GetMapping(value = "/previous/doctor/{doctorId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<List<upcomingAppointmentDto>> getPreviousByDoctor(
            @PathVariable String doctorId,
            @AuthenticationPrincipal String firebaseDocUID)
            throws ExecutionException, InterruptedException {
        List<upcomingAppointmentDto> list = appointmentsService.getPreviousAppointmentsByDoctor(firebaseDocUID);
        return ResponseEntity.ok(list);
    }
  @PostMapping
public ResponseEntity<?> createAppointment(
        @Valid @RequestBody appointmentCreateRequestDto request,
        @AuthenticationPrincipal String firebaseDocUID) {
    try {
        appointmentDto created = appointmentsService.createAppointment(firebaseDocUID, request);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("appointmentId", created.getAppointmentId());
        res.put("message", "Appointment booked successfully");

        return ResponseEntity.status(HttpStatus.CREATED).body(res);

    } catch (IllegalStateException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(err);

    } catch (IllegalArgumentException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(err);

    } catch (Exception e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", "Failed to create appointment");
        System.out.println(e.getClass().getSimpleName() + ": " + e.getMessage());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(err);
    }
}
@DeleteMapping(value = "/{appointmentId}", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<Map<String, Object>> cancel(
        @PathVariable String appointmentId,
        @AuthenticationPrincipal String firebaseDocUID) {
    try {
        appointmentsService.cancelAppointment(firebaseDocUID, appointmentId);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("message", "Appointment cancelled successfully");
        res.put("appointmentId", appointmentId);

        return ResponseEntity.ok(res);

    } catch (IllegalStateException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(err);

    } catch (IllegalArgumentException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.badRequest().body(err);

    } catch (Exception e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", "Failed to cancel appointment");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(err);
    }
}
@PostMapping(value = "/join/{appointmentId}", produces = MediaType.APPLICATION_JSON_VALUE)
public ResponseEntity<?> joinAppointment(
        @PathVariable String appointmentId,
        @AuthenticationPrincipal String firebaseDocUID) {
    try {
        JoinMeetingResponseDto response =
                agoraMeetingService.joinAppointment(firebaseDocUID, appointmentId);

        return ResponseEntity.ok(response);

    } catch (IllegalArgumentException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err);

    } catch (SecurityException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(err);

    } catch (IllegalStateException e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", e.getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT).body(err);

    } catch (Exception e) {
        Map<String, Object> err = new HashMap<>();
        err.put("success", false);
        err.put("message", "Failed to load meeting session");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(err);
    }
}
}
