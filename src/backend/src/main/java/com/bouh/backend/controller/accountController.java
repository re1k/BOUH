package com.bouh.backend.controller;

import com.bouh.backend.model.Dto.*;
import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.profiles.doctorUpdateDto;
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

    /** Registers a new caregiver account. */
    @PostMapping("/register/caregivers")
    public ResponseEntity<Void> createCaregiver(
            @RequestBody caregiverDto dto,
            @AuthenticationPrincipal String firebaseDocUID) {

        accountService.createCaregiverAccount(firebaseDocUID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /** Registers a new doctor account. */
    @PostMapping("/register/doctors")
    public ResponseEntity<Void> createDoctor(
            @RequestBody doctorDto dto,
            @AuthenticationPrincipal String firebaseDocUID) {

        accountService.createDoctorAccount(firebaseDocUID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /** Returns authenticated user role and basic info. */
    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal String firebaseDocUID) {
        return ResponseEntity.ok(accountService.resolveAuthState(firebaseDocUID));
    }

    /** Deletes user account based on role. */
    @DeleteMapping("/delete")
    public ResponseEntity<accountResponseDto> deleteUser(
            @AuthenticationPrincipal String firebaseDocUID) {

        accountResponseDto response = accountService.deleteUsersAccount(firebaseDocUID);
        return ResponseEntity.status(response.isSuccess() ? 200 : 409).body(response);
    }

    /** Updates user FCM token. */
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

    /** Returns profile based on user role. */
    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(
            @AuthenticationPrincipal String firebaseDocUID) {

        return ResponseEntity.ok(accountService.getUserProfile(firebaseDocUID));
    }

    /** Updates doctor profile fields. */
    @PatchMapping("/doctor/update")
    public ResponseEntity<accountResponseDto> updateDoctor(
            @AuthenticationPrincipal String firebaseDocUID,
            @RequestBody doctorUpdateDto dto) {

                log.info("[[ Updating doctor info ]]");
        return ResponseEntity.ok(
                accountService.updateDoctor(firebaseDocUID, dto));
    }

    /** Updates caregiver name. */
    @PatchMapping("/caregiver/update")
    public ResponseEntity<accountResponseDto> updateCaregiver(
            @AuthenticationPrincipal String firebaseDocUID,
            @RequestBody Map<String, String> body) {

        String name = body.get("name");

        return ResponseEntity.ok(
                accountService.updateCaregiver(firebaseDocUID, name));
    }
}