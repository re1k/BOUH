package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.DoctorManagement;
import com.bouh.backend.model.Dto.DoctorStatsDTO;
import com.bouh.backend.service.DoctorManagementService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.concurrent.ExecutionException;
import com.bouh.backend.model.Dto.Qualificationrequestdto;

@RestController
@RequestMapping("/api/admin/doctors")
public class DoctorManagementController {
    private final DoctorManagementService doctorManagementService;

    public DoctorManagementController(DoctorManagementService doctorManagementService) {
        this.doctorManagementService = doctorManagementService;
    }

    // GET /api/admin/doctors/pending
    @GetMapping("/pending")
    public ResponseEntity<List<DoctorManagement>> getPendingDoctors(
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(doctorManagementService.getPendingDoctors());
    }

    // GET /api/admin/doctors/approved
    @GetMapping("/approved")
    public ResponseEntity<List<DoctorManagement>> getApprovedDoctors(
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(doctorManagementService.getApprovedDoctors());
    }

    // GET /api/admin/doctors/stats
    @GetMapping("/stats")
    public ResponseEntity<DoctorStatsDTO> getDoctorStats(
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(doctorManagementService.getDoctorStats());
    }

    // PATCH /api/admin/doctors/{uid}/accept
    @PatchMapping("/{uid}/accept")
    public ResponseEntity<Void> acceptDoctor(
            @PathVariable String uid,
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        doctorManagementService.acceptDoctor(uid);
        return ResponseEntity.ok().build();
    }

    // PATCH /api/admin/doctors/{uid}/reject
    @PatchMapping("/{uid}/reject")
    public ResponseEntity<Void> rejectDoctor(
            @PathVariable String uid,
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        doctorManagementService.rejectDoctor(uid);
        return ResponseEntity.ok().build();
    }

    // GET /api/admin/doctors/qualification-requests
    @GetMapping("/qualification-requests")
    public ResponseEntity<List<Qualificationrequestdto>> getPendingQualificationRequests(
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        return ResponseEntity.ok(doctorManagementService.getPendingQualificationRequests());
    }

    // PATCH /api/admin/doctors/qualification-requests/{requestId}/accept
    @PatchMapping("/qualification-requests/{requestId}/accept")
    public ResponseEntity<Void> acceptQualificationRequest(
            @PathVariable String requestId,
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        doctorManagementService.acceptQualificationRequest(requestId);
        return ResponseEntity.ok().build();
    }

    // PATCH /api/admin/doctors/qualification-requests/{requestId}/reject
    @PatchMapping("/qualification-requests/{requestId}/reject")
    public ResponseEntity<Void> rejectQualificationRequest(
            @PathVariable String requestId,
            Authentication authentication)
            throws ExecutionException, InterruptedException {
        doctorManagementService.rejectQualificationRequest(requestId);
        return ResponseEntity.ok().build();
    }
}
