package com.bouh.backend.controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.bouh.backend.model.Dto.ImageClassifier.ClassificationRequestDto;
import com.bouh.backend.model.Dto.ImageClassifier.ClassificationResponseDto;
import com.bouh.backend.service.classification.ClassificationService;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/classification")
public class ClassifierController {

    private final ClassificationService classificationService;

    public ClassifierController(ClassificationService classificationService) {
        this.classificationService = classificationService;
    }

    @PostMapping("/request")
    public ClassificationResponseDto classifyImage(
            @RequestBody ClassificationRequestDto request) throws Exception {

        log.info("[[ . . Classification Controller is running. . ]]");
        long startTime = System.currentTimeMillis();

        String prediction = classificationService.classify(request.getImagePath());

        long endTime = System.currentTimeMillis();
        long duration = endTime - startTime;

        log.info("[[[. . . Classification process took {} ms for image {} . . .]]]", duration, request.getImagePath());

        return new ClassificationResponseDto(prediction);
    }
}