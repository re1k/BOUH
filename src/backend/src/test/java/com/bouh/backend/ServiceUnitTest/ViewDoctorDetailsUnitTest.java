package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.bouh.backend.model.Dto.DoctorDetailsDto;
import com.bouh.backend.model.repository.doctorRepo;
import com.bouh.backend.service.doctors.DoctorsService;

@ExtendWith(MockitoExtension.class)
public class ViewDoctorDetailsUnitTest {

    @Mock
    private doctorRepo doctorRepo;

    @InjectMocks
    private DoctorsService doctorsService;

    @Test
    void getDoctorDetails_shouldReturnDoctorDetailsWithCorrectFields() throws Exception {
        
        // Mock the repository to return a populated DoctorDetailsDto for the given doctorId
        String doctorId = "vj3inj1KveMSSbTo2G8z04O252l1";
        DoctorDetailsDto expectedDto = new DoctorDetailsDto();
        expectedDto.setDoctorID(doctorId);
        expectedDto.setName("د. أحمد");
        expectedDto.setEmail("doctor@gmail.com");
        expectedDto.setGender("Male");
        expectedDto.setAverageRating(4.5);
        expectedDto.setAreaOfKnowledge("غضب");
        expectedDto.setQualifications(List.of("دكتوراه", "ماجستير"));
        expectedDto.setYearsOfExperience(3);
        expectedDto.setProfilePhotoURL("https://example.com/photo.jpg");
        when(doctorRepo.getDoctorDetails(doctorId)).thenReturn(expectedDto);

        // Call the method under test
        DoctorDetailsDto result = doctorsService.getDoctorDetails(doctorId);

        // Verify that the repository method was called with the correct doctorId
        verify(doctorRepo).getDoctorDetails(doctorId);

        // Verify that all fields in the returned DTO match the expected values
        assertNotNull(result);
        assertEquals(doctorId, result.getDoctorID());
        assertEquals("د. أحمد", result.getName());
        assertEquals("doctor@gmail.com", result.getEmail());
        assertEquals("Male", result.getGender());
        assertEquals(4.5, result.getAverageRating());
        assertEquals("غضب", result.getAreaOfKnowledge());
        assertEquals(List.of("دكتوراه", "ماجستير"), result.getQualifications());
        assertEquals(3, result.getYearsOfExperience());
        assertEquals("https://example.com/photo.jpg", result.getProfilePhotoURL());
    }

}
