package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.CaregiverManagement;
import com.bouh.backend.service.CaregiverManagementservice;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/admin/caregivers")
public class CaregiverManagementcontroller {
    private final CaregiverManagementservice caregiverInfoService;

    public CaregiverManagementcontroller(CaregiverManagementservice caregiverInfoService) {
        this.caregiverInfoService = caregiverInfoService;
    }

    // GET /api/admin/caregivers
    // Returns all caregivers with name and email
    // Requires: Authorization: Bearer <Firebase JWT>
    @GetMapping
    public ResponseEntity<List<CaregiverManagement>> getAllCaregivers(
            Authentication authentication)
            throws ExecutionException, InterruptedException {

        List<CaregiverManagement> caregivers = caregiverInfoService.getAllCaregivers();
        return ResponseEntity.ok(caregivers);
    }
}
