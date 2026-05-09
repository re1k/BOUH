package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import com.google.cloud.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
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

import com.bouh.backend.config.TimeSlotConfig;
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

        @InjectMocks
        private AppointmentsService appointmentsService;

        /*
         * Empty case for upcoming: when the repository returns no upcoming
         * appointments, the service must return a non-null empty list.
         */
        @Test
        void getUpcomingAppointments_shouldReturnEmptyList()
                        throws ExecutionException, InterruptedException {

                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>());

                List<upcomingAppointmentDto> result = appointmentsService.getUpcomingAppointments("caregiver123");

                verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");
                assertNotNull(result);
                assertTrue(result.isEmpty());
        }

        /*
         * Empty case for previous: when both the past repo and the upcoming
         * repo return empty, the service must return a non-null empty list.
         */
        @Test
        void getPreviousAppointments_shouldReturnEmptyList()
                        throws ExecutionException, InterruptedException {

                when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>());
                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>());

                List<upcomingAppointmentDto> result = appointmentsService.getPreviousAppointments("caregiver123");

                verify(appointmentRepo).findPastByCaregiverId("caregiver123");
                verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");
                assertNotNull(result);
                assertTrue(result.isEmpty());
        }

        /*
         * Partition test: the same same-day appointment is fed to BOTH service
         * methods and must land in upcoming only — never in previous.
         * assumeTrue skips the test when no future slot exists today (e.g. after 9 PM).
         */
        @Test
        void sameDayNotPassed_shouldBePartitionedToUpcoming()
                        throws ExecutionException, InterruptedException {

                LocalTime currentTime = ZonedDateTime
                                .now(ZoneId.of("Asia/Riyadh"))
                                .toLocalTime();

                int validSlot = -1;
                for (int i = 0; i < TimeSlotConfig.SLOT_COUNT; i++) {
                        if (TimeSlotConfig.slotStart(i).isAfter(currentTime)) {
                                validSlot = i;
                                break;
                        }
                }
                assumeTrue(validSlot >= 0, "No future slot available right now");

                LocalDate today = LocalDate.now(ZoneId.of("Asia/Riyadh"));
                ZonedDateTime startZdt = today
                                .atTime(TimeSlotConfig.slotStart(validSlot))
                                .atZone(ZoneId.of("Asia/Riyadh"));

                appointmentDto appointment = new appointmentDto();
                appointment.setAppointmentId("notPassedToday");
                appointment.setCaregiverId("caregiver123");
                appointment.setDoctorId("doctor123");
                appointment.setChildId("child123");
                appointment.setTimeSlotId(String.valueOf(validSlot));
                appointment.setStartDateTime(
                                Timestamp.ofTimeSecondsAndNanos(startZdt.toEpochSecond(), 0));
                appointment.setStatus(1);
                appointment.setRated(false);

                // thenAnswer returns a fresh list per call; production removeIf mutates it
                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenAnswer(inv -> new ArrayList<>(List.of(appointment)));
                when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                                .thenAnswer(inv -> new ArrayList<>());

                // upcoming: must keep it (slot has not ended)
                List<upcomingAppointmentDto> upcoming = appointmentsService.getUpcomingAppointments("caregiver123");
                assertNotNull(upcoming);
                assertEquals(1, upcoming.size());
                assertEquals("notPassedToday", upcoming.get(0).getAppointmentId());

                // previous: must NOT pull it in (only same-day passed get pulled)
                List<upcomingAppointmentDto> previous = appointmentsService.getPreviousAppointments("caregiver123");
                assertNotNull(previous);
                assertTrue(previous.isEmpty());
        }

        /*
         * Partition test: the same same-day appointment is fed to BOTH service
         * methods and must land in previous only — never in upcoming.
         * assumeTrue skips the test when the chosen slot has not ended yet today.
         */
        @Test
        void sameDayPassed_shouldBePartitionedToPrevious()
                        throws ExecutionException, InterruptedException {

                // Slot 0 = 4:00 PM – 4:30 PM (real production slot, not the morning demo one)
                int passedSlot = 0;

                LocalTime currentTime = ZonedDateTime
                                .now(ZoneId.of("Asia/Riyadh"))
                                .toLocalTime();
                assumeTrue(
                                TimeSlotConfig.slotEnd(passedSlot).isBefore(currentTime),
                                "4:00 PM slot has not passed yet");

                LocalDate today = LocalDate.now(ZoneId.of("Asia/Riyadh"));
                ZonedDateTime startZdt = today
                                .atTime(TimeSlotConfig.slotStart(passedSlot))
                                .atZone(ZoneId.of("Asia/Riyadh"));

                appointmentDto appointment = new appointmentDto();
                appointment.setAppointmentId("passedToday");
                appointment.setCaregiverId("caregiver123");
                appointment.setDoctorId("doctor123");
                appointment.setChildId("child123");
                appointment.setTimeSlotId(String.valueOf(passedSlot));
                appointment.setStartDateTime(
                                Timestamp.ofTimeSecondsAndNanos(startZdt.toEpochSecond(), 0));
                appointment.setStatus(1);
                appointment.setRated(false);

                // thenAnswer returns a fresh list per call; production removeIf mutates it
                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenAnswer(inv -> new ArrayList<>(List.of(appointment)));
                when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                                .thenAnswer(inv -> new ArrayList<>());

                // upcoming: must drop it (removeIf strips same-day passed slots)
                List<upcomingAppointmentDto> upcoming = appointmentsService.getUpcomingAppointments("caregiver123");
                assertNotNull(upcoming);
                assertTrue(upcoming.isEmpty());

                // previous: must transition it in (same-day passed gets appended to past)
                List<upcomingAppointmentDto> previous = appointmentsService.getPreviousAppointments("caregiver123");
                assertNotNull(previous);
                assertEquals(1, previous.size());
                assertEquals("passedToday", previous.get(0).getAppointmentId());
        }

        /*
         * Sort test for upcoming: repo returns appointments in scrambled order
         * on purpose; the service is responsible for sorting them nearest-first
         * before returning.
         */
        @Test
        void getUpcomingAppointments_shouldBeOrderedNearestFirst()
                        throws ExecutionException, InterruptedException {

                Instant base = Instant.now();
                appointmentDto in7Days = buildBasicAppointment("in7", base.plusSeconds(7 * 86400));
                appointmentDto in1Day  = buildBasicAppointment("in1", base.plusSeconds(86400));
                appointmentDto in3Days = buildBasicAppointment("in3", base.plusSeconds(3 * 86400));

                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>(List.of(in7Days, in1Day, in3Days)));

                List<upcomingAppointmentDto> result = appointmentsService.getUpcomingAppointments("caregiver123");

                verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");
                assertNotNull(result);
                assertEquals(3, result.size());
                assertEquals("in1", result.get(0).getAppointmentId());
                assertEquals("in3", result.get(1).getAppointmentId());
                assertEquals("in7", result.get(2).getAppointmentId());
        }

        /*
         * Sort test for previous: repo returns past appointments in scrambled
         * order on purpose; the service is responsible for sorting them
         * newest-first before returning.
         */
        @Test
        void getPreviousAppointments_shouldBeOrderedNewestFirst()
                        throws ExecutionException, InterruptedException {

                Instant base = Instant.now();
                appointmentDto sevenDaysAgo = buildBasicAppointment("p7", base.minusSeconds(7 * 86400));
                appointmentDto oneDayAgo    = buildBasicAppointment("p1", base.minusSeconds(86400));
                appointmentDto threeDaysAgo = buildBasicAppointment("p3", base.minusSeconds(3 * 86400));

                when(appointmentRepo.findPastByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>(List.of(sevenDaysAgo, oneDayAgo, threeDaysAgo)));
                when(appointmentRepo.findUpcomingByCaregiverId("caregiver123"))
                                .thenReturn(new ArrayList<>());

                List<upcomingAppointmentDto> result = appointmentsService.getPreviousAppointments("caregiver123");

                verify(appointmentRepo).findPastByCaregiverId("caregiver123");
                verify(appointmentRepo).findUpcomingByCaregiverId("caregiver123");
                assertNotNull(result);
                assertEquals(3, result.size());
                assertEquals("p1", result.get(0).getAppointmentId());
                assertEquals("p3", result.get(1).getAppointmentId());
                assertEquals("p7", result.get(2).getAppointmentId());
        }

        /*
         * Helper: builds a minimal appointmentDto with the given id and start
         * time. Used by sort tests that don't care about slot-of-day boundaries.
         */
        private appointmentDto buildBasicAppointment(String id, Instant when) {
                appointmentDto a = new appointmentDto();
                a.setAppointmentId(id);
                a.setCaregiverId("caregiver123");
                a.setDoctorId("doctor123");
                a.setChildId("child123");
                a.setStartDateTime(
                                Timestamp.ofTimeSecondsAndNanos(when.getEpochSecond(), 0));
                a.setStatus(1);
                a.setRated(false);
                return a;
        }
}
