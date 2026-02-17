package com.bouh.backend.service;
import com.bouh.backend.model.Dto.caregiverDto;
import com.bouh.backend.model.repository.caregiverRepo;
import org.springframework.stereotype.Service;

@Service
public class testImpl {

        private final caregiverRepo caregiverRepository;
        public testImpl(caregiverRepo caregiverRepository) {
            this.caregiverRepository = caregiverRepository;
        }
        //Contact the Repo to execute adding
        public caregiverDto createCaregiver(caregiverDto caregiver) throws Exception {
            return caregiverRepository.addCaregiver(caregiver);
        }
    }

