package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<Void> forgotPassword(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        if (email != null && !email.isBlank()) adminService.forgotPassword(email);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> me(@AuthenticationPrincipal String firebaseDocUID) {
        // If we reach here, AdminAuthFilter already verified the user is an admin
        return ResponseEntity.ok(Map.of(
                "uid", firebaseDocUID,
                "role", "admin"
        ));
    }

    @DeleteMapping("/doctors/delete/{uid}")
    public ResponseEntity<accountResponseDto> deleteDoctor(@PathVariable String uid) {
        return ResponseEntity.ok(adminService.deleteDoctor(uid));
    }

    @DeleteMapping("/caregivers/delete/{uid}")
    public ResponseEntity<accountResponseDto> deleteCaregiver(@PathVariable String uid) {
        return ResponseEntity.ok(adminService.deleteCaregiver(uid));
    }
}
