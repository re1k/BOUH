package com.bouh.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> me(@AuthenticationPrincipal String firebaseDocUID) {
        // If we reach here, AdminAuthFilter already verified the user is an admin
        return ResponseEntity.ok(Map.of(
                "uid", firebaseDocUID,
                "role", "admin"
        ));
    }
}
