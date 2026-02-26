package com.bouh.backend.service;
import com.bouh.backend.model.Dto.authDto;
import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;
import org.springframework.stereotype.Service;

@Service
public class accountService {

        private final caregiverRepo caregiverRepository;
        private final doctorRepo doctorRepository;

        public accountService(caregiverRepo caregiverRepo, doctorRepo doctorRepo) {
            this.caregiverRepository = caregiverRepo;
            this.doctorRepository = doctorRepo;
        }

    public void createCaregiverAccount(String uid, caregiverDto Dto) {
        try {
            caregiverRepository.createCaregiver(uid, Dto);
        } catch (Exception e) {
            throw new RuntimeException(
                    "Failed to create caregiver account for uid=" + uid, e
            );
        }
    }

    public void createDoctorAccount(String uid, doctorDto Dto) {

        Dto.setRegistrationStatus("PENDING");
        Dto.setAverageRating(0.0);
        Dto.setFcmToken(null);
        Dto.setProfilePhotoURL(null);
        Dto.setSchedule(null);
        Dto.setScfhsnumber(Dto.getScfhsnumber());
        Dto.setIban(Dto.getIban());

        try {
            doctorRepository.createDoctor(uid, Dto);
        } catch (Exception e) {
            throw new RuntimeException(
                    "Failed to create doctor account for uid=" + uid, e
            );
        }
    }

    public authDto resolveAuthState(String uid) {

        doctorDto doctor = doctorRepository.findByUid(uid);

        if (doctor!= null) {
            return new authDto(
                    uid,
                    "doctor",
                    doctor.getRegistrationStatus()
            );
        }
        if (caregiverRepository.existsByUid(uid)) {
            return new authDto(
                    uid,
                    "caregiver",
                    null
            );
        }
        //user with no profile (rare case)
        return new authDto(
                uid,
                null,
                null
        );
    }
}



