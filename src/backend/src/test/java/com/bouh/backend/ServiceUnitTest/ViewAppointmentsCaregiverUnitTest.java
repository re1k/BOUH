package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import com.google.cloud.Timestamp;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.upcomingAppointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.doctorRepo;
import com.bouh.backend.model.repository.childrenRepo;
import com.bouh.backend.service.GcsImageService;
import com.bouh.backend.service.appointments.AppointmentsService;

@ExtendWith(MockitoExtension.class)
public class ViewAppointmentsCaregiverUnitTest {

    @Mock
    private AppointmentRepo appointmentRepo;

    @Mock
    private doctorRepo doctorRepo;

    @Mock
    private childrenRepo childrenRepo;

    @Mock
    private GcsImageService gcsImageService;

    // SERVICE UNDER TEST
    @InjectMocks
    private AppointmentsService AppointmentsService;

    /*
     * Get upcoming appointments should return an appointment
     */
    @Test
    void getUpcomingAppointments_shouldReturnUpcomingAppointments()
            throws ExecutionException, InterruptedException {

        List<appointmentDto> mockAppointments = new ArrayList<>();

        appointmentDto appointment = new appointmentDto();
        // Arrange
        appointment.setAppointmentId("appt1");
        appointment.setCaregiverId("caregiver123");
        appointment.setDoctorId("doctor123");
        appointment.setChildId("child123");
        appointment.setTimeSlotId("slot123");
        appointment.setStartDateTime(
                Timestamp.ofTimeSecondsAndNanos(
                        Instant.now().plusSeconds(86400).getEpochSecond(),
                        0));

        appointment.setEndTime("11:00 AM");
        appointment.setMeetingLink("https://meet.agora.com/test-room");
        appointment.setAmount(200L);
        appointment.setStatus(1);
        appointment.setPaymentIntentId("pi_123456789");
        appointment.setRated(false);
        mockAppointments.add(appointment);

        when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                .thenReturn(mockAppointments);

        // Act
        List<upcomingAppointmentDto> result = AppointmentsService.getUpcomingAppointments("caregiver123");

        // Assert
        verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");

        assertNotNull(result);
        assertEquals(1, result.size());

        upcomingAppointmentDto dto = result.get(0);

        assertEquals("appt1", dto.getAppointmentId());
        assertEquals("doctor123", dto.getDoctorId());
        assertEquals("child123", dto.getChildId());
        assertEquals(
                "https://meet.agora.com/test-room",
                dto.getMeetingLink());

        assertEquals(
                "pi_123456789",
                dto.getPaymentIntentId());
        assertEquals(1, dto.getStatus());
        assertFalse(dto.getRated());
    }

    /*
     * Get upcoming appointments should return empty list
     */
    @Test
    void getUpcomingAppointments_shouldReturnEmptyList()
            throws ExecutionException, InterruptedException {

        when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                .thenReturn(new ArrayList<>());

        // Act
        List<upcomingAppointmentDto> result = AppointmentsService.getUpcomingAppointments("caregiver123");

        // Assert
        verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");

        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    /*
     * Get previous appointments should return appointment
     */
    @Test
    void getPreviousAppointments_shouldReturnPreviousAppointments()
            throws ExecutionException, InterruptedException {

        List<appointmentDto> pastAppointments = new ArrayList<>();
        List<appointmentDto> upcomingAppointments = new ArrayList<>();

        // Past appointment
        appointmentDto past = new appointmentDto();

        past.setAppointmentId("past1");
        past.setCaregiverId("caregiver123");
        past.setDoctorId("doctor123");
        past.setChildId("child123");
        past.setTimeSlotId("slotPast");
        past.setStartDateTime(
                Timestamp.ofTimeSecondsAndNanos(
                        Instant.now().minusSeconds(86400).getEpochSecond(),
                        0));

        past.setEndTime("11:00 AM");
        past.setMeetingLink("https://meet.agora.com/test-room");
        past.setAmount(200L);
        past.setStatus(1);
        past.setPaymentIntentId("pi_past123");
        past.setRated(true);

        // Upcoming appointment
        appointmentDto upcoming = new appointmentDto();

        upcoming.setAppointmentId("upcoming1");
        upcoming.setCaregiverId("caregiver123");
        upcoming.setDoctorId("doctor456");
        upcoming.setChildId("child456");
        upcoming.setTimeSlotId("slotUpcoming");

        upcoming.setStartDateTime(
                Timestamp.ofTimeSecondsAndNanos(
                        Instant.now().plusSeconds(86400).getEpochSecond(),
                        0));

        upcoming.setEndTime("03:00 PM");
        upcoming.setMeetingLink("https://meet.agora.com/test-room");
        upcoming.setAmount(300L);
        upcoming.setStatus(0);
        upcoming.setPaymentIntentId("pi_upcoming123");
        upcoming.setRated(false);

        pastAppointments.add(past);
        upcomingAppointments.add(upcoming);

        when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                .thenReturn(pastAppointments);

        when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                .thenReturn(upcomingAppointments);

        // Act
        List<upcomingAppointmentDto> result = AppointmentsService.getPreviousAppointments("caregiver123");

        // Assert
        verify(appointmentRepo).findPastByCaregiverId("caregiver123");
        verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");

        assertNotNull(result);
        assertEquals(1, result.size());

        upcomingAppointmentDto dto = result.get(0);

        assertEquals("past1", dto.getAppointmentId());
        assertEquals("doctor123", dto.getDoctorId());
        assertEquals("child123", dto.getChildId());
        assertEquals(
                "https://meet.agora.com/test-room",
                dto.getMeetingLink());
        assertEquals(
                "pi_past123",
                dto.getPaymentIntentId());
        assertEquals(1, dto.getStatus());
        assertTrue(dto.getRated());
    }

    /*
     * Get previous appointments should return empty list
     */
    @Test
    void getPreviousAppointments_shouldReturnEmptyList()
            throws ExecutionException, InterruptedException {

        // Arrange
        when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                .thenReturn(new ArrayList<>());

        when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                .thenReturn(new ArrayList<>());

        // Act
        List<upcomingAppointmentDto> result = AppointmentsService.getPreviousAppointments("caregiver123");

        // Assert
        verify(appointmentRepo).findPastByCaregiverId("caregiver123");

        verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");

        assertNotNull(result);
        assertTrue(result.isEmpty());

    }

    /*
     * Passed today's appointment should not appear
     * in upcoming appointments anymore and should
     * appear in previous appointments
     */
    @Test
    void getPreviousAppointments_shouldIncludePassedTodayAppointments()
            throws ExecutionException, InterruptedException {

        // Arrange
        List<appointmentDto> upcomingAppointments = new ArrayList<>();
        appointmentDto passedTodayAppointment = new appointmentDto();

        passedTodayAppointment.setAppointmentId("today1");
        passedTodayAppointment.setCaregiverId("caregiver123");
        passedTodayAppointment.setDoctorId("doctor123");
        passedTodayAppointment.setChildId("child123");

        // Service logic determines whether an appointment is passed
        // using slot times from TimeSlotConfig and the current Riyadh time.
        // We create a valid slot start time that has already
        // passed today so the appointment is treated as "previous"
        // instead of "upcoming".
        ZonedDateTime riyadhToday = ZonedDateTime.now(ZoneId.of("Asia/Riyadh"));

        LocalTime currentTime = riyadhToday.toLocalTime();

        if (currentTime.isAfter(LocalTime.of(16, 30))) {

            // Use 4:00 PM slot because its 4:30 PM
            // slot end time already passed
            riyadhToday = riyadhToday
                    .withHour(16)
                    .withMinute(0)
                    .withSecond(0)
                    .withNano(0);

        } else if (currentTime.isAfter(LocalTime.of(9, 30))) {

            // Use 9:00 AM slot because its 9:30 AM
            // slot end time already passed
            riyadhToday = riyadhToday
                    .withHour(9)
                    .withMinute(0)
                    .withSecond(0)
                    .withNano(0);

        } else {

            // Before 9:30 AM no configured slot has fully passed yet,
            // so this edge-case test cannot reliably succeed
            return;
        }

        passedTodayAppointment.setStartDateTime(
                Timestamp.ofTimeSecondsAndNanos(
                        riyadhToday.toEpochSecond(),
                        0));
        passedTodayAppointment.setEndTime("09:30 AM");
        passedTodayAppointment.setMeetingLink(
                "https://meet.agora.com/test-room");
        passedTodayAppointment.setAmount(250L);
        passedTodayAppointment.setStatus(1);
        passedTodayAppointment.setPaymentIntentId("pi_today123");
        passedTodayAppointment.setRated(false);

        upcomingAppointments.add(passedTodayAppointment);

        // Mock repository responses
        when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                .thenReturn(new ArrayList<>());

        when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                .thenReturn(upcomingAppointments);

        // Act
        // Get upcoming and previous appointments
        List<upcomingAppointmentDto> upcomingResult = AppointmentsService.getUpcomingAppointments(
                "caregiver123");

        List<upcomingAppointmentDto> previousResult = AppointmentsService.getPreviousAppointments(
                "caregiver123");

        // Assert
        // Appointment should move from upcoming to previous
        verify(appointmentRepo)
                .findPastByCaregiverId("caregiver123");

        verify(appointmentRepo)
                .findUpcomingByCaregiverId("caregiver123");

        assertEquals(0, upcomingResult.size());
        assertEquals(1, previousResult.size());

        upcomingAppointmentDto dto = previousResult.get(0);

        assertEquals("today1", dto.getAppointmentId());
        assertEquals("caregiver123", dto.getCaregiverId());
        assertEquals("doctor123", dto.getDoctorId());
        assertEquals("child123", dto.getChildId());
        assertEquals(1, dto.getStatus());
        assertEquals(
                "https://meet.agora.com/test-room",
                dto.getMeetingLink());
        assertFalse(dto.getRated());
    }
}