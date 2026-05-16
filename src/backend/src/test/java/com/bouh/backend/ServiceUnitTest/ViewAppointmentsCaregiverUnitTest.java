package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import com.google.cloud.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.doctorDto;
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

        private static final String CAREGIVER_ID = "cgVr8KmN2pQwYx5Lt7BzAhD3F1Js";
        private static final String DOCTOR_ID = "vj3inj1KveMSSbTo2G8z04O252l1";
        private static final String CHILD_ID = "chK7mP3nQrJ8wXyZtBvL";
        private static final String DOCTOR_NAME = "د. سارة خالد";
        private static final String DOCTOR_AREA = "حزن";
        private static final String DOCTOR_PROFILE_OBJECT_PATH = "doctorProfileImages/vj3inj1KveMSSbTo2G8z04O252l1_1778325911255.jpg";
        private static final String CHILD_NAME = "ليلى";

        /*
         * Empty case for upcoming: when the repository returns no upcoming
         * appointments, the service must return a non-null empty list.
         */
        @Test
        void getUpcomingAppointments_shouldReturnEmptyList()
                        throws ExecutionException, InterruptedException {

                when(appointmentRepo.findUpcomingByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>());

                List<upcomingAppointmentDto> result = appointmentsService.getUpcomingAppointments(CAREGIVER_ID);

                verify(appointmentRepo).findUpcomingByCaregiverId(CAREGIVER_ID);
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

                when(appointmentRepo.findPastByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>());
                when(appointmentRepo.findUpcomingByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>());

                List<upcomingAppointmentDto> result = appointmentsService.getPreviousAppointments(CAREGIVER_ID);

                verify(appointmentRepo).findPastByCaregiverId(CAREGIVER_ID);
                verify(appointmentRepo).findUpcomingByCaregiverId(CAREGIVER_ID);
                assertNotNull(result);
                assertTrue(result.isEmpty());
        }

        /*
         * get sorted upcoming appointments view for caregivers
         */
        @Test
        void getUpcomingAppointments_shouldBeOrderedNearestFirstAndEnriched()
                        throws ExecutionException, InterruptedException {

                String idIn1Day  = "apA1bC2dE3fG4hI5jK6l";
                String idIn3Days = "apM7nO8pQ9rS0tU1vW2x";
                String idIn7Days = "apY3zA4bC5dE6fG7hI8j";

                Instant base = Instant.now();
                appointmentDto in7Days = buildBasicAppointment(idIn7Days, base.plusSeconds(7 * 86400), 1, false);
                appointmentDto in1Day = buildBasicAppointment(idIn1Day, base.plusSeconds(86400), 1, false);
                appointmentDto in3Days = buildBasicAppointment(idIn3Days, base.plusSeconds(3 * 86400), 1, false);

                when(appointmentRepo.findUpcomingByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>(List.of(in7Days, in1Day, in3Days)));

                when(doctorRepo.findByUid(DOCTOR_ID)).thenReturn(doctorDtoForCaregiverView());
                when(childrenRepo.findChildName(CAREGIVER_ID, CHILD_ID)).thenReturn(CHILD_NAME);
                when(gcsImageService.generateDownloadUrl(DOCTOR_PROFILE_OBJECT_PATH))
                                .thenReturn(DOCTOR_PROFILE_OBJECT_PATH);

                // Call the method under test
                List<upcomingAppointmentDto> result = appointmentsService.getUpcomingAppointments(CAREGIVER_ID);

                // Verify that the repository method was called with the correct caregiverId
                verify(appointmentRepo).findUpcomingByCaregiverId(CAREGIVER_ID);

                // Verify that the appointments are sorted nearest-first
                assertNotNull(result);
                assertEquals(3, result.size());
                assertEquals(idIn1Day,  result.get(0).getAppointmentId());
                assertEquals(idIn3Days, result.get(1).getAppointmentId());
                assertEquals(idIn7Days, result.get(2).getAppointmentId());

                assertCaregiverViewRow(result.get(0), 1, Boolean.FALSE);
                assertCaregiverViewRow(result.get(1), 1, Boolean.FALSE);
                assertCaregiverViewRow(result.get(2), 1, Boolean.FALSE);
        }


        /*
         * get sorted previous appointments for caregivers
         */
        @Test
        void getPreviousAppointments_shouldBeOrderedNewestFirstAndEnriched()
                        throws ExecutionException, InterruptedException {

                String idOneDayAgo    = "apK1lM2nO3pQ4rS5tU6v";
                String idThreeDaysAgo = "apW7xY8zA9bC0dE1fG2h";
                String idSevenDaysAgo = "apI3jK4lM5nO6pQ7rS8t";

                Instant base = Instant.now();
                appointmentDto sevenDaysAgo = buildBasicAppointment(
                                idSevenDaysAgo, base.minusSeconds(7 * 86400), null, true);
                appointmentDto oneDayAgo = buildBasicAppointment(
                                idOneDayAgo, base.minusSeconds(86400), 1, true);
                appointmentDto threeDaysAgo = buildBasicAppointment(
                                idThreeDaysAgo, base.minusSeconds(3 * 86400), 0, false);

                when(appointmentRepo.findPastByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>(List.of(sevenDaysAgo, oneDayAgo, threeDaysAgo)));
                when(appointmentRepo.findUpcomingByCaregiverId(CAREGIVER_ID))
                                .thenReturn(new ArrayList<>());

                when(doctorRepo.findByUid(DOCTOR_ID)).thenReturn(doctorDtoForCaregiverView());
                when(childrenRepo.findChildName(CAREGIVER_ID, CHILD_ID)).thenReturn(CHILD_NAME);
                when(gcsImageService.generateDownloadUrl(DOCTOR_PROFILE_OBJECT_PATH))
                                .thenReturn(DOCTOR_PROFILE_OBJECT_PATH);

                // Call the method under test
                List<upcomingAppointmentDto> result = appointmentsService.getPreviousAppointments(CAREGIVER_ID);

                // Verify that both repository methods were called with the correct caregiverId
                verify(appointmentRepo).findPastByCaregiverId(CAREGIVER_ID);
                verify(appointmentRepo).findUpcomingByCaregiverId(CAREGIVER_ID);

                // Verify that the appointments are sorted newest-first
                assertNotNull(result);
                assertEquals(3, result.size());
                assertEquals(idOneDayAgo,    result.get(0).getAppointmentId());
                assertEquals(idThreeDaysAgo, result.get(1).getAppointmentId());
                assertEquals(idSevenDaysAgo, result.get(2).getAppointmentId());

                assertCaregiverViewRow(result.get(0), 1, Boolean.TRUE);
                assertCaregiverViewRow(result.get(1), 0, Boolean.FALSE);
                assertCaregiverViewRow(result.get(2), 0, Boolean.TRUE);
        }

        private static void assertCaregiverViewRow(
                        upcomingAppointmentDto dto, int expectedStatus, Boolean expectedRated) {
                assertEquals(DOCTOR_NAME, dto.getDoctorName());
                assertEquals(DOCTOR_AREA, dto.getDoctorAreaOfKnowledge());
                assertEquals(DOCTOR_PROFILE_OBJECT_PATH, dto.getDoctorProfilePhotoURL());
                assertEquals(CHILD_NAME, dto.getChildName());
                assertEquals(Integer.valueOf(expectedStatus), dto.getStatus());
                assertEquals(expectedRated, dto.getRated());
        }

        private static doctorDto doctorDtoForCaregiverView() {
                doctorDto d = new doctorDto();
                d.setName(DOCTOR_NAME);
                d.setAreaOfKnowledge(DOCTOR_AREA);
                d.setProfilePhotoURL(DOCTOR_PROFILE_OBJECT_PATH);
                return d;
        }

        private appointmentDto buildBasicAppointment(
                        String id, Instant when, Integer status, Boolean rated) {
                appointmentDto a = new appointmentDto();
                a.setAppointmentId(id);
                a.setCaregiverId(CAREGIVER_ID);
                a.setDoctorId(DOCTOR_ID);
                a.setChildId(CHILD_ID);
                a.setStartDateTime(Timestamp.ofTimeSecondsAndNanos(when.getEpochSecond(), 0));
                a.setStatus(status);
                a.setRated(rated);
                return a;
        }
}
