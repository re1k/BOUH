package com.bouh.backend.service;

import com.bouh.backend.model.Dto.DoctorManagement;
import com.bouh.backend.model.Dto.DoctorStatsDTO;
import com.bouh.backend.model.repository.DoctorManagementRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;
import com.bouh.backend.model.Dto.Qualificationrequestdto;

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

    public List<Qualificationrequestdto> getPendingQualificationRequests()
            throws ExecutionException, InterruptedException {
        return doctorManagementRepository.getPendingQualificationRequests();
    }

    public void acceptQualificationRequest(String requestId)
            throws ExecutionException, InterruptedException {

        // 1. Get doctorId from the request
        String doctorId = doctorManagementRepository.getDoctorIdFromRequest(requestId);

        // 2. Apply new qualifications to doctor document
        doctorManagementRepository.applyQualificationUpdate(doctorId, requestId);

        // 3. Delete the request document
        doctorManagementRepository.deleteQualificationRequest(requestId);

        // 4. Send acceptance email
        String[] emailAndName = doctorManagementRepository.getDoctorEmailAndName(doctorId);
        if (emailAndName != null) {
            emailService.sendQualificationAcceptedEmail(emailAndName[0], emailAndName[1]);
        }
    }

    public void rejectQualificationRequest(String requestId)
            throws ExecutionException, InterruptedException {

        // 1. Get doctorId before deleting
        String doctorId = doctorManagementRepository.getDoctorIdFromRequest(requestId);

        // 2. Delete the request document (no qualification update)
        doctorManagementRepository.deleteQualificationRequest(requestId);

        // 3. Send rejection email
        String[] emailAndName = doctorManagementRepository.getDoctorEmailAndName(doctorId);
        if (emailAndName != null) {
            emailService.sendQualificationRejectedEmail(emailAndName[0], emailAndName[1]);
        }
    }
}
