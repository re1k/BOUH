package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityDayDto;
import com.bouh.backend.model.Dto.AvailabilitySchedule.AvailabilityStoredSlotDto;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.AvailabilityScheduleRepo;
import com.bouh.backend.service.appointments.AppointmentsService;
import com.google.cloud.Timestamp;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.HashSet;
import java.util.List;

@ExtendWith(MockitoExtension.class)
public class CancelAppointmentUnitTest {

    @Mock
    private AppointmentRepo appointmentRepo;

    @Mock
    private AvailabilityScheduleRepo availabilityScheduleRepo;

    @InjectMocks
    private AppointmentsService appointmentsService;

    @Test
    void cancelAppointment_shouldCancelSuccessfully() throws Exception {

        // Create fake appointment
        appointmentDto appointment = new appointmentDto();
        appointment.setAppointmentId("YH5q4wANmIq5Hv81hUHT");
        appointment.setCaregiverId("eFXGJMjrouTwE3uj0FaVAS6evAf2");
        appointment.setDoctorId("vj3inj1KveMSSbTo2G8z04O252l1");

        // Appointment after 2 hours
       ZonedDateTime future = ZonedDateTime.now(ZoneId.of("Asia/Riyadh"))
        .plusDays(1)
        .withHour(16)
        .withMinute(30)
        .withSecond(0)
        .withNano(0);

        appointment.setStartDateTime(
                Timestamp.ofTimeSecondsAndNanos(
                        future.toEpochSecond(),
                        future.getNano()
                )
        );

        // Mock repo
        when(appointmentRepo.findById("YH5q4wANmIq5Hv81hUHT"))
                .thenReturn(appointment);

        // Fake availability slot
        AvailabilityStoredSlotDto slot = new AvailabilityStoredSlotDto();
        slot.setIndex(1);
        slot.setBooked(true);

        AvailabilityDayDto day = new AvailabilityDayDto();
        day.setSlots(List.of(slot));

        when(availabilityScheduleRepo.getDay(eq("vj3inj1KveMSSbTo2G8z04O252l1"), anyString()))
                .thenReturn(day);

        // Call service
        appointmentsService.cancelAppointment("eFXGJMjrouTwE3uj0FaVAS6evAf2", "YH5q4wANmIq5Hv81hUHT");

        // Verify delete called
        verify(appointmentRepo).deleteByIdAtomically("YH5q4wANmIq5Hv81hUHT");

        // Verify availability fetched
        verify(availabilityScheduleRepo).getDay(
                eq("vj3inj1KveMSSbTo2G8z04O252l1"),
                eq(future.toLocalDate().toString())
        );

        // Verify availability updated
        verify(availabilityScheduleRepo).update(
                eq("vj3inj1KveMSSbTo2G8z04O252l1"),
                argThat(map -> {
                AvailabilityDayDto updatedDay = map.get(future.toLocalDate().toString());

                return updatedDay != null &&
                        !updatedDay.getSlots().get(0).isBooked();
                }),
                eq(new HashSet<>())
        );
    }

        @Test
        void cancelAppointment_shouldThrowWhenAppointmentNotFound() throws Exception {
        // Mock repo to return null appointment
        when(appointmentRepo.findById("YH5q4wANmIq5Hv81hUHT"))
                .thenReturn(null);
        // Verify exception is thrown
        assertThrows(
                IllegalArgumentException.class,
                () -> appointmentsService.cancelAppointment("eFXGJMjrouTwE3uj0FaVAS6evAf2", "YH5q4wANmIq5Hv81hUHT")
        );

        verify(appointmentRepo).findById("YH5q4wANmIq5Hv81hUHT");

        verify(appointmentRepo, never())
        .deleteByIdAtomically(anyString());

        verify(availabilityScheduleRepo, never())
                .getDay(anyString(), anyString());

        verify(availabilityScheduleRepo, never())
                .update(anyString(), anyMap(), anySet());
        }



    @Test
        void cancelAppointment_shouldThrowWhenLessThan30Minutes() throws Exception {
        // Create fake appointment
                appointmentDto appointment = new appointmentDto();
                appointment.setCaregiverId("eFXGJMjrouTwE3uj0FaVAS6evAf2");
                appointment.setDoctorId("vj3inj1KveMSSbTo2G8z04O252l1");

                // Appointment after 10 minutes
                Instant future = Instant.now().plusSeconds(600);

                appointment.setStartDateTime(
                        Timestamp.ofTimeSecondsAndNanos(
                                future.getEpochSecond(),
                                future.getNano()
                        )
                );
        // Mock repo
                when(appointmentRepo.findById("YH5q4wANmIq5Hv81hUHT"))
                        .thenReturn(appointment);
        // Verify exception is thrown
                assertThrows(
                        IllegalStateException.class,
                        () -> appointmentsService.cancelAppointment("eFXGJMjrouTwE3uj0FaVAS6evAf2", "YH5q4wANmIq5Hv81hUHT")
                );

        verify(appointmentRepo).findById("YH5q4wANmIq5Hv81hUHT");

        verify(appointmentRepo, never())
        .deleteByIdAtomically(anyString());

        verify(availabilityScheduleRepo, never())
                .getDay(anyString(), anyString());

        verify(availabilityScheduleRepo, never())
                .update(anyString(), anyMap(), anySet());

        }

}