package com.bouh.backend.service;

import com.bouh.backend.model.Dto.*;
import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.accountManagment.authDto;
import com.bouh.backend.model.Dto.profiles.caregiverProfileResponseDto;
import com.bouh.backend.model.Dto.profiles.doctorUpdateDto;
import com.bouh.backend.model.repository.ProfilesRepo;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class AccountService {

    private final caregiverRepo caregiverRepository;
    private final doctorRepo doctorRepository;
    private final ProfilesRepo profilesRepo;

    public AccountService(caregiverRepo caregiverRepo, doctorRepo doctorRepo, ProfilesRepo profilesRepo) {
        this.caregiverRepository = caregiverRepo;
        this.doctorRepository = doctorRepo;
        this.profilesRepo = profilesRepo;
    }

    /** Creates a caregiver account */
    public void createCaregiverAccount(String uid, caregiverDto Dto) {
        caregiverRepository.createCaregiver(uid, Dto);
    }

    /** Creates a doctor account */
    public void createDoctorAccount(String uid, doctorDto Dto) {
        doctorRepository.createDoctor(uid, Dto);
    }

    /** Determines user role (doctor/caregiver) and basic info. */
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

    /** Deletes user account based on role with conditional handling for doctors. */
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

    /** Updates FCM token for doctor or caregiver. */
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

    /** Updates doctor profile fields. */
    public accountResponseDto updateDoctor(String uid, doctorUpdateDto dto) {
        try {
            log.info("Updating doctor profile for uid={}", uid);

            profilesRepo.updateDoctor(uid, dto);

            return new accountResponseDto(
                    true,
                    "PROFILE_UPDATED",
                    "تم تحديث بيانات الدكتور");

        } catch (Exception e) {
            log.error("Failed to update doctor profile for uid={}", uid, e);

            return new accountResponseDto(
                    false,
                    "UPDATE_FAILED",
                     e.getMessage() != null ? e.getMessage() : "فشل تحديث بيانات الدكتور");
        }
    }

    /** Updates caregiver name. */
    public accountResponseDto updateCaregiver(String uid, String name) {
        try {
            log.info("Updating caregiver name for uid={}", uid);

            profilesRepo.updateCaregiverName(uid, name);

            return new accountResponseDto(
                    true,
                    "PROFILE_UPDATED",
                    "تم تحديث الاسم");

        } catch (Exception e) {
            log.error("Failed to update caregiver name for uid={}", uid, e);

            return new accountResponseDto(
                    false,
                    "UPDATE_FAILED",
                    "فشل تحديث الاسم");
        }
    }

    /** Returns user profile Information based on role (doctor or caregiver). */
    public Object getUserProfile(String uid) {

        String role = resolveAuthState(uid).getRole();

        try {
            log.info("[[ .. Fetching profile for uid={}, role={} .. ]]", uid, role);

            if ("doctor".equals(role)) {

                return profilesRepo.getDoctorProfile(uid);

            } else if ("caregiver".equals(role)) {

                return profilesRepo.getCaregiverProfile(uid);

            } else {
                throw new RuntimeException("Invalid role");
            }

        } catch (Exception e) {
            log.error("Failed to fetch profile for uid={}, role={}", uid, role, e);
            throw new RuntimeException("Failed to fetch profile", e);
        }
    }

}