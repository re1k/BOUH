package com.bouh.backend.controller.payment;

import com.bouh.backend.model.Dto.payment.RefundRequestDto;
import com.bouh.backend.model.Dto.payment.RefundResponseDto;
import com.bouh.backend.service.payment.RefundService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

@RestController
@RequestMapping("/api/payment")
public class RefundController {

    private final RefundService refundService;

    public RefundController(RefundService refundService) {
        this.refundService = refundService;
    }

    @PostMapping("/refund")
    public ResponseEntity<RefundResponseDto> refund(@Valid @RequestBody RefundRequestDto request,
            Authentication authentication) {
        String uid = authentication.getName();
        return ResponseEntity.ok(refundService.refund(request, uid));
    }
}
