package com.bouh.backend.controller;
import java.util.concurrent.CompletableFuture;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.bouh.backend.model.Dto.RateDto;
import com.bouh.backend.service.RateService;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/rate")
public class RateController {

    private final RateService rateService;

    public RateController(RateService rateService) {
        this.rateService = rateService;
    }

    @PostMapping("/add")
    public ResponseEntity<?> rateDoctor(
            @RequestBody RateDto dto) throws Exception {
    log.info("[[Rating a doctor]]");

    //validation
    if (dto == null || dto.getRating() < 1.0 || dto.getRating() > 5.0) {
    return ResponseEntity.badRequest().build();
    }

    //fire-and-forget
    CompletableFuture.runAsync(() -> {
        try {
            rateService.rateDoctor(dto);
        } catch (Exception e) {
            log.error("Error processing rating", e);
        }
    });
    return ResponseEntity.status(HttpStatus.CREATED).build();
}
}