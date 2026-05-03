package com.bouh.backend.service;

import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.adminRepo;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;
import com.bouh.backend.service.payment.RefundService;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class AdminService {

    private final doctorRepo doctorRepository;
    private final caregiverRepo caregiverRepository;
    private final EmailService emailService;
    private final adminRepo adminRepository;
    private final RestTemplate restTemplate;
    private final RefundService refundService;
    private final AppointmentRepo appointmentRepo;

    @Value("${firebase.web.api-key}")
    private String firebaseWebApiKey;

    public AdminService(doctorRepo doctorRepo, caregiverRepo caregiverRepo, EmailService emailService,
                        adminRepo adminRepo, RestTemplate restTemplate,
                        RefundService refundService, AppointmentRepo appointmentRepo) {
        this.doctorRepository = doctorRepo;
        this.caregiverRepository = caregiverRepo;
        this.emailService = emailService;
        this.adminRepository = adminRepo;
        this.restTemplate = restTemplate;
        this.refundService = refundService;
        this.appointmentRepo = appointmentRepo;
    }

    public void forgotPassword(String email) {
        try {
            UserRecord user = FirebaseAuth.getInstance().getUserByEmail(email.trim());
            if (!adminRepository.isAdmin(user.getUid())) return;
            String url = "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=" + firebaseWebApiKey;
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, String>> request = new HttpEntity<>(
                    Map.of("requestType", "PASSWORD_RESET", "email", email.trim()), headers);
            restTemplate.postForEntity(url, request, String.class);
        } catch (Exception e) {
            log.warn("Password reset failed for email={}: {}", email, e.getMessage());
        }
    }

    public accountResponseDto deleteDoctor(String uid) {
        doctorDto doctor = doctorRepository.findByUid(uid);
        if (doctor == null) {
            return new accountResponseDto(false, "NOT_FOUND", "الطبيب غير موجود");
        }

        String doctorEmail = doctor.getEmail();
        String doctorName = doctor.getName();

        // Refund all upcoming appointments and notify caregivers by email
        try {
            List<appointmentDto> upcoming = appointmentRepo.findUpcomingByDoctorId(uid);
            for (appointmentDto appt : upcoming) {
                try {
                    if (appt.getPaymentIntentId() != null && !appt.getPaymentIntentId().isBlank()) {
                        refundService.refundByAdmin(appt.getPaymentIntentId());
                    }
                    if (appt.getCaregiverId() != null && !appt.getCaregiverId().isBlank()) {
                        caregiverDto caregiver = caregiverRepository.findByUid(appt.getCaregiverId());
                        if (caregiver != null && caregiver.getEmail() != null) {
                            emailService.sendDoctorDeletedRefundEmail(
                                    caregiver.getEmail(), caregiver.getName(), doctorName);
                        }
                    }
                    appointmentRepo.deleteByIdAtomically(appt.getAppointmentId());
                } catch (Exception e) {
                    log.error("Failed to process appointment id={} for doctor uid={}: {}",
                            appt.getAppointmentId(), uid, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch upcoming appointments for doctor uid={}: {}", uid, e.getMessage());
        }

        // Soft-delete the doctor
        doctorRepository.deleteDoctorAsync(uid, doctor);

        if (doctorEmail != null) {
            emailService.sendAccountDeletionEmail(doctorEmail, doctorName);
        }

        return new accountResponseDto(true, "ACCOUNT_DELETED", "تم حذف الحساب");
    }

    public accountResponseDto deleteCaregiver(String uid) {
        caregiverDto caregiver = caregiverRepository.findByUid(uid);
        if (caregiver == null) {
            return new accountResponseDto(false, "NOT_FOUND", "المستخدم غير موجود");
        }

        String email = caregiver.getEmail();
        String name = caregiver.getName();
        caregiverRepository.deleteCaregiver(uid);
        emailService.sendAccountDeletionEmail(email, name);
        return new accountResponseDto(true, "ACCOUNT_DELETED", "تم حذف الحساب");
    }

}
