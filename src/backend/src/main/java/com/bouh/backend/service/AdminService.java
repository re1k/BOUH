package com.bouh.backend.service;

import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.repository.adminRepo;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Slf4j
@Service
public class AdminService {

    private final doctorRepo doctorRepository;
    private final caregiverRepo caregiverRepository;
    private final EmailService emailService;
    private final adminRepo adminRepository;
    private final RestTemplate restTemplate;

    @Value("${firebase.web.api-key}")
    private String firebaseWebApiKey;

    public AdminService(doctorRepo doctorRepo, caregiverRepo caregiverRepo, EmailService emailService, adminRepo adminRepo, RestTemplate restTemplate) {
        this.doctorRepository = doctorRepo;
        this.caregiverRepository = caregiverRepo;
        this.emailService = emailService;
        this.adminRepository = adminRepo;
        this.restTemplate = restTemplate;
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
            log.warn("Password reset failed silently for email={}", email);
        }
    }

    public accountResponseDto deleteDoctor(String uid) {
        doctorDto doctor = doctorRepository.findByUid(uid);
        if (doctor == null) {
            return new accountResponseDto(false, "NOT_FOUND", "الطبيب غير موجود");
        }

        String email = doctor.getEmail();
        String name = doctor.getName();
        String result = doctorRepository.deleteDoctor(uid);

        switch (result) {
            case "deleted":
                emailService.sendAccountDeletionEmail(email, name);
                return new accountResponseDto(true, "ACCOUNT_DELETED", "تم حذف الحساب");
            case "upcoming-appointment-found":
                return new accountResponseDto(false, "HAS_UPCOMING_APPOINTMENTS",
                        "لا يمكن حذف الحساب لوجود مواعيد قادمة");
            default:
                return new accountResponseDto(false, "UNKNOWN_ERROR", "حدث خطأ غير متوقع");
        }
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
