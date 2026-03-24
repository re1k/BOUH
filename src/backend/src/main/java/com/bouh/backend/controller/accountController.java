package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.*;
import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.service.AccountService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping("/register/caregivers")
    public ResponseEntity<Map<String, Object>> createCaregiver(
            @RequestBody caregiverDto dto,
            @AuthenticationPrincipal String firebaseDocUID) {

        accountService.createCaregiverAccount(firebaseDocUID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/register/doctors")
    public ResponseEntity<Map<String, Object>> createDoctor(
            @RequestBody doctorDto dto,
            @AuthenticationPrincipal String firebaseDocUID) {

        accountService.createDoctorAccount(firebaseDocUID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal String firebaseDocUID) {
        return ResponseEntity.ok(accountService.resolveAuthState(firebaseDocUID));
    }

    @DeleteMapping("/delete")
    public ResponseEntity<accountResponseDto> deleteUser(@AuthenticationPrincipal String firebaseDocUID) {
        accountResponseDto response = accountService.deleteUsersAccount(firebaseDocUID);
        return ResponseEntity.status(response.isSuccess() ? 200 : 409).body(response);
    }

    @PutMapping("/fcmToken")
    public ResponseEntity<Void> updateFcmToken(
            @AuthenticationPrincipal String firebaseDocUID,
            @RequestBody Map<String, String> body) {

        String fcmToken = body.get("fcmToken");
        boolean updated = accountService.updateUserFcmToken(firebaseDocUID, fcmToken);
        return updated
                ? ResponseEntity.noContent().build()
                : ResponseEntity.notFound().build();
    }
}