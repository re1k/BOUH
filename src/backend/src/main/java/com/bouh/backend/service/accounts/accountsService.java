package com.bouh.backend.service.accounts;

import com.bouh.backend.model.Dto.*;
import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.accountManagment.authDto;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;

import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;

@Slf4j
@Service
public class accountsService {

    private final caregiverRepo caregiverRepository;
    private final doctorRepo doctorRepository;

    public accountsService(caregiverRepo caregiverRepo, doctorRepo doctorRepo) {
        this.caregiverRepository = caregiverRepo;
        this.doctorRepository = doctorRepo;
    }

    public void createCaregiverAccount(String uid, caregiverDto Dto) {
        caregiverRepository.createCaregiver(uid, Dto);
    }

    public void createDoctorAccount(String uid, doctorDto Dto) {
        doctorRepository.createDoctor(uid, Dto);
    }

    public authDto resolveAuthState(String uid) {

        doctorDto doctor = doctorRepository.findByUid(uid);
        caregiverDto caregiver = caregiverRepository.findByUid(uid);

        if (doctor != null) {
            return new authDto(
                    uid,
                    "doctor",
                    doctor.getName(),
                    doctor.getRegistrationStatus());
        }
        if (caregiver != null) {
            return new authDto(
                    uid,
                    "caregiver",
                    caregiver.getName(),
                    null);
        }
        // user with no profile
        return new authDto(
                uid,
                null,
                null,
                null);
    }

    public accountResponseDto deleteUsersAccount(String uid) {

        String role = resolveAuthState(uid).getRole();
        if (role.equals("caregiver")) {
            caregiverRepository.deleteCaregiver(uid);
            return new accountResponseDto(true, "ACCOUNT_DELETED", "تم حذف الحساب");
        } else {
            String result = doctorRepository.deleteDoctor(uid);
            switch (result) {
                case "deleted":
                    return new accountResponseDto(true, "ACCOUNT_DELETED", "تم حذف الحساب");
                case "upcoming-appointment-found":
                    return new accountResponseDto(false, "HAS_UPCOMING_APPOINTMENTS",
                            "لا يمكن حذف الحساب لوجود مواعيد قادمة");
                default:
                    return new accountResponseDto(false, "UNKNOWN_ERROR",
                            "حدث خطأ غير متوقع");
            }
        }
    }

    public boolean updateUserFcmToken(String uid, String fcmToken) {
        if (fcmToken == null || fcmToken.isBlank()) {
            return false;
        }
        authDto auth = resolveAuthState(uid);
        String role = auth.getRole();
        switch (role) {
            case "doctor":
                doctorRepository.updateFcmToken(uid, fcmToken);
                return true;
            case "caregiver":
                caregiverRepository.updateFcmToken(uid, fcmToken);
                return true;
            default:
                return false;
        }
    }
}