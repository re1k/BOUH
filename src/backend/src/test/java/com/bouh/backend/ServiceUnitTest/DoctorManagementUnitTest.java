package com.bouh.backend.ServiceUnitTest;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import com.bouh.backend.model.repository.DoctorManagementRepository;
import com.bouh.backend.service.DoctorManagementService;
import com.bouh.backend.service.EmailService;

@ExtendWith(MockitoExtension.class)
public class DoctorManagementUnitTest {

    @Mock
    private DoctorManagementRepository doctorManagementRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private DoctorManagementService doctorManagementService;

    @Test
    void acceptDoctor_shouldApproveDoctorAndSendEmail() throws Exception {
        // Mock the repository to return email and name for the doctor
        when(doctorManagementRepository.getDoctorEmailAndName("vj3inj1KveMSSbTo2G8z04O252l1"))
                .thenReturn(new String[]{"doctor@gmail.com", "د. سارة خالد"});

        // Call the method under test
        doctorManagementService.acceptDoctor("vj3inj1KveMSSbTo2G8z04O252l1");

        // Verify that the repository method to update status was called with correct parameters
        verify(doctorManagementRepository).updateRegistrationStatus("vj3inj1KveMSSbTo2G8z04O252l1", "APPROVED");

        // Verify that the email service was called to send the acceptance email
        verify(emailService).sendRegistrationAcceptedEmail("doctor@gmail.com", "د. سارة خالد");
    }

    @Test
    void rejectDoctor_shouldDeleteDoctorAndSendEmail() throws Exception {
        // Mock the repository to return email and name for the doctor
        when(doctorManagementRepository.getDoctorEmailAndName("vj3inj1KveMSSbTo2G8z04O252l1"))
                .thenReturn(new String[]{"doctor@gmail.com", "د. سارة خالد"});

        // Call the method under test
        doctorManagementService.rejectDoctor("vj3inj1KveMSSbTo2G8z04O252l1");

        // Verify that the repository method to delete the doctor was called with correct parameters
        verify(doctorManagementRepository).deleteDoctor("vj3inj1KveMSSbTo2G8z04O252l1");

        // Verify that the email service was called to send the rejection email
        verify(emailService).sendRegistrationRejectedEmail("doctor@gmail.com", "د. سارة خالد");
    }
}

