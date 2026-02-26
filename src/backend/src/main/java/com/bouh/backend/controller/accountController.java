package com.bouh.backend.controller;
import com.bouh.backend.model.Dto.*;
import com.bouh.backend.service.accountService;
import lombok.extern.slf4j.Slf4j;
import org.hibernate.mapping.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

@Slf4j
@RestController
@RequestMapping("/api/accounts")
public class accountController {

    private final accountService accountService;
    public accountController(accountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping("/register/caregivers")
    public ResponseEntity<Void> createCaregiver(
    @RequestBody caregiverDto dto,
            Authentication authentication) {

        log.info("createCaregiver called for uid={}", authentication.getName());
        //who is making this request
        String uid = authentication.getName();

        accountService.createCaregiverAccount(uid, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @PostMapping("/register/doctors")
    public ResponseEntity<Void> createDoctor(
            @RequestBody doctorDto dto,
            Authentication authentication) {
        log.info("createDoctor called for uid={}", authentication.getName());

        //who is making this request
        String uid = authentication.getName();

        accountService.createDoctorAccount(uid, dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }


    @GetMapping("/me")
    public ResponseEntity<?> me(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            //resolving users roles
            String uid = authentication.getName();
            return ResponseEntity.ok(
                    accountService.resolveAuthState(uid)
            );
        } catch (Exception e) {
            log.error("Failed to resolve role", e);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("INTERNAL_ERROR");
        }
    }


}
