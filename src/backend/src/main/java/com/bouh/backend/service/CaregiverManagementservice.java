package com.bouh.backend.service;

import com.bouh.backend.model.Dto.CaregiverManagement;
import com.bouh.backend.model.repository.CaregiverManagementRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class CaregiverManagementservice {
    private final CaregiverManagementRepository caregiverInfoRepository;

    public CaregiverManagementservice(CaregiverManagementRepository caregiverInfoRepository) {
        this.caregiverInfoRepository = caregiverInfoRepository;
    }

    public List<CaregiverManagement> getAllCaregivers() throws ExecutionException, InterruptedException {
        return caregiverInfoRepository.findAllCaregivers();
    }
}
