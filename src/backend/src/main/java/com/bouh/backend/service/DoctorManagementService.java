package com.bouh.backend.service;

import com.bouh.backend.model.Dto.DoctorManagement;
import com.bouh.backend.model.Dto.DoctorStatsDTO;
import com.bouh.backend.model.repository.DoctorManagementRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class DoctorManagementService {
    private final DoctorManagementRepository doctorManagementRepository;
    private final EmailService emailService;

    public DoctorManagementService(
            DoctorManagementRepository doctorManagementRepository,
            EmailService emailService) {
        this.doctorManagementRepository = doctorManagementRepository;
        this.emailService = emailService;
    }

    public List<DoctorManagement> getPendingDoctors() throws ExecutionException, InterruptedException {
        return doctorManagementRepository.findDoctorsByStatus("PENDING");
    }

    public List<DoctorManagement> getApprovedDoctors() throws ExecutionException, InterruptedException {
        return doctorManagementRepository.findDoctorsByStatus("APPROVED");
    }

    public DoctorStatsDTO getDoctorStats() throws ExecutionException, InterruptedException {
        return doctorManagementRepository.getDoctorStats();
    }

    public void acceptDoctor(String uid) throws ExecutionException, InterruptedException {
        doctorManagementRepository.updateRegistrationStatus(uid, "APPROVED");

        String[] emailAndName = doctorManagementRepository.getDoctorEmailAndName(uid);
        if (emailAndName != null) {
            emailService.sendRegistrationAcceptedEmail(emailAndName[0], emailAndName[1]);
        }
    }

    public void rejectDoctor(String uid) throws ExecutionException, InterruptedException {
        doctorManagementRepository.updateRegistrationStatus(uid, "REJECTED");

        String[] emailAndName = doctorManagementRepository.getDoctorEmailAndName(uid);
        if (emailAndName != null) {
            emailService.sendRegistrationRejectedEmail(emailAndName[0], emailAndName[1]);
        }
    }
}
