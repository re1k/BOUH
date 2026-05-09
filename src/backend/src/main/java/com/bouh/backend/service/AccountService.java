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

    private static final String DOCTOR_NAME_HONORIFIC = "د. ";

    /** Updates doctor profile fields. */
    public accountResponseDto updateDoctor(String uid, doctorUpdateDto dto) {
        validateUpdateRequest(dto);

        // Normalize name: collapse spaces while preserving the "د. " prefix
        if (dto.getName() != null) {
            String raw = dto.getName().trim();
            if (raw.startsWith(DOCTOR_NAME_HONORIFIC)) {
                String body = raw.substring(DOCTOR_NAME_HONORIFIC.length()).trim().replaceAll("\\s+", " ");
                dto.setName(DOCTOR_NAME_HONORIFIC + body);
            }
        }

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

    private void validateUpdateRequest(doctorUpdateDto dto) {

        // Name validation:
        if (dto.getName() != null) {
            String raw = dto.getName().trim();
            if (raw.isEmpty())
                throw new IllegalArgumentException("name is required");

            // Strip "د. " honorific prefix if present
            // Remove extra spaces between words
            String body = raw.startsWith(DOCTOR_NAME_HONORIFIC)
                    ? raw.substring(DOCTOR_NAME_HONORIFIC.length()).trim()
                    : raw;
            String normalizedBody = body.replaceAll("\\s+", " ");

            if (normalizedBody.length() > 20)
                throw new IllegalArgumentException("name must not exceed 20 characters");
            if (normalizedBody.matches(".*[a-zA-Z].*"))
                throw new IllegalArgumentException("name must be in Arabic only");
            if (normalizedBody.matches(".*[0-9\\u0660-\\u0669\\u06F0-\\u06F9].*"))
                throw new IllegalArgumentException("name cannot contain numbers or special characters");
            // Disallow tatweel and Arabic punctuation symbols (e.g. ـ ، ؛ ؟)
            if (normalizedBody.matches(".*[\\u0640\\u060C\\u061B\\u061F\\u066A-\\u066D\\u06DD\\u06DE\\u06E9\\uFD3C\\uFD3D].*"))
                throw new IllegalArgumentException("name cannot contain numbers or special characters");

            // Allow Arabic letters and spaces only
            if (!normalizedBody.matches("[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\s]+"))
                throw new IllegalArgumentException("name cannot contain numbers or special characters");
        }

        // Gender validation:
        if (dto.getGender() != null) {
            String gender = dto.getGender().trim();
            if (gender.isEmpty())
                throw new IllegalArgumentException("gender is required");
            if (!gender.equals("male") && !gender.equals("female"))
                throw new IllegalArgumentException("gender must be male or female");
        }

        // Years of experience validation:
        if (dto.getYearsOfExperience() != null) {
            // Valid range is 1 to 5
            if (dto.getYearsOfExperience() < 1 || dto.getYearsOfExperience() > 5)
                throw new IllegalArgumentException("yearsOfExperience must be between 1 and 5");
        }

        // Qualifications validation:
        if (dto.getQualifications() != null) {
            if (dto.getQualifications().isEmpty())
                throw new IllegalArgumentException("qualifications must not be empty");
            if (dto.getQualifications().size() > 12)
                throw new IllegalArgumentException("qualifications must not exceed 12 items");
            for (String q : dto.getQualifications()) {
                if (q == null || q.trim().isEmpty()) continue;
                String trimmed = q.trim();
                if (trimmed.length() > 70)
                    throw new IllegalArgumentException("each qualification must not exceed 70 characters");
                if (trimmed.matches(".*[a-zA-Z].*"))
                    throw new IllegalArgumentException("qualifications must be in Arabic only");
                // Allow:
                // - Arabic letters
                // - Numbers
                // - Spaces and basic punctuation
                if (!trimmed.matches("[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF0-9\\s.,]+"))
                    throw new IllegalArgumentException("qualifications contain invalid characters");
            }
        }

        // Iban validation:
        if (dto.getIban() != null) {
            if (dto.getIban().trim().isEmpty())
                throw new IllegalArgumentException("iban is required");
            // Must match Saudi IBAN format: SA followed by 22 digits
            if (!dto.getIban().trim().matches("SA[0-9]{22}"))
                throw new IllegalArgumentException("iban must be a valid Saudi IBAN (SA followed by 22 digits)");
        }

        // Profile photo URL validation:
        if (dto.getProfilePhotoURL() != null && dto.getProfilePhotoURL().trim().isEmpty())
            throw new IllegalArgumentException("profilePhotoURL cannot be empty");
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