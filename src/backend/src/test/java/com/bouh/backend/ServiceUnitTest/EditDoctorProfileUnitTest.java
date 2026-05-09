package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

import com.bouh.backend.model.Dto.accountManagment.accountResponseDto;
import com.bouh.backend.model.Dto.profiles.doctorUpdateDto;
import com.bouh.backend.model.repository.ProfilesRepo;
import com.bouh.backend.service.AccountService;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
public class EditDoctorProfileUnitTest {

    @Mock
    private ProfilesRepo profilesRepo;

    @InjectMocks
    private AccountService accountService;

    // Shared doctor ID used in all test cases
    private final String doctorId = "vj3inj1KveMSSbTo2G8z04O252l1";

    // Helper method to create doctorUpdateDto objects
    private doctorUpdateDto createRequest(
            String name,
            String gender,
            List<String> qualifications,
            Integer yearsOfExperience,
            String profilePhotoURL,
            String iban
    ) {
        return new doctorUpdateDto(name, gender, qualifications, yearsOfExperience, profilePhotoURL, iban);
    }

    @Test
    void updateDoctorProfile_shouldReturnSuccess_whenAllFieldsAreValid() {

        // Create a valid update request
        doctorUpdateDto request = createRequest(
                "د. ريماز",
                "female",
                List.of("طب الأطفال", "الطب النفسي للأطفال"),
                3,
                "https://example.com/photo.jpg",
                "SA1234567890123456789012"
        );

        // Mock repository behavior
        doNothing().when(profilesRepo).updateDoctor(doctorId, request);

        // Call the method under test
        accountResponseDto result = accountService.updateDoctor(doctorId, request);

        // Verify repository interactions
        verify(profilesRepo).updateDoctor(doctorId, request);

        // Verify returned DTO fields
        assertNotNull(result);
        assertTrue(result.isSuccess());
        assertEquals("PROFILE_UPDATED", result.getCode());
        assertEquals("تم تحديث بيانات الدكتور", result.getMessage());
    }

    @Test
    void updateDoctorProfile_shouldNormalizeMultipleSpacesInName() {

        // Create a request with a name that contains multiple spaces
        doctorUpdateDto request = createRequest(
                "د.   ريماز  ",
                null,
                null,
                null,
                null,
                null
        );

        // Mock repository behavior
        doNothing().when(profilesRepo).updateDoctor(eq(doctorId), any(doctorUpdateDto.class));

        // Call service
        accountService.updateDoctor(doctorId, request);

        // Verify spaces were normalized correctly
        verify(profilesRepo).updateDoctor(eq(doctorId), argThat(dto -> "د. ريماز".equals(dto.getName())));
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameIsBlank() {

        // Create a request with a blank name
        doctorUpdateDto request = createRequest(
                "     ",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name is required", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameExceedsTwentyCharacters() {

        // Create a request with a long name
        doctorUpdateDto request = createRequest(
                "د. سارة عبدالعزيز سعود عبدالله",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name must not exceed 20 characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameContainsEnglishLetters() {

        // Create a request with English letters in the name
        doctorUpdateDto request = createRequest(
                "Remaz ريماز",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name must be in Arabic only", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameContainsNumbers() {

        // Create a request with numbers in the name
        doctorUpdateDto request = createRequest(
                "ريماز123",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name cannot contain numbers or special characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameContainsSpecialCharacters() {

        // Create a request with special characters in the name
        doctorUpdateDto request = createRequest(
                "ريماز@",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name cannot contain numbers or special characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenNameContainsDisallowedArabicSymbols() {

        // Create a request with a disallowed Arabic symbol in the name
        doctorUpdateDto request = createRequest(
                "ريمازـ",
                null,
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("name cannot contain numbers or special characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenGenderIsBlank() {

        // Create a request with a blank gender
        doctorUpdateDto request = createRequest(
                null,
                "   ",
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("gender is required", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenGenderIsInvalid() {

        // Create a request with an invalid gender value
        doctorUpdateDto request = createRequest(
                null,
                "unknown",
                null,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("gender must be male or female", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenYearsOfExperienceIsBelowMinimum() {

        // Create a request with yearsOfExperience below the allowed minimum
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                0,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("yearsOfExperience must be between 1 and 5", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenYearsOfExperienceExceedsMaximum() {

        // Create a request with yearsOfExperience above the allowed maximum
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                6,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("yearsOfExperience must be between 1 and 5", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenQualificationsListIsEmpty() {

        // Create a request with an empty qualifications list
        doctorUpdateDto request = createRequest(
                null,
                null,
                List.of(),
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("qualifications must not be empty", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenQualificationsExceedMaxCount() {

        // Build a list with 13 qualifications exceeding the maximum of 12
        List<String> tooMany = List.of(
                "طب الأطفال",
                "الطب النفسي للأطفال",
                "علم النفس",
                "الإرشاد النفسي",
                "التربية الخاصة",
                "علاج النطق",
                "العلاج الوظيفي",
                "طب الأسرة",
                "الطب النفسي",
                "علم نفس النمو",
                "الصحة النفسية",
                "طب المجتمع",
                "الرعاية الاجتماعية"
        );

        // Create a request with qualifications exceeding the maximum
        doctorUpdateDto request = createRequest(
                null,
                null,
                tooMany,
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("qualifications must not exceed 12 items", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenQualificationItemContainsEnglish() {

        // Create a request with English in a qualification item
        doctorUpdateDto request = createRequest(
                null,
                null,
                List.of("MBBS"),
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("qualifications must be in Arabic only", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenQualificationItemContainsInvalidCharacters() {

        // Create a request with an invalid special character in a qualification item
        doctorUpdateDto request = createRequest(
                null,
                null,
                List.of("طب الأطفال@"),
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("qualifications contain invalid characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenQualificationItemExceedsMaxLength() {

        // Create a request with a qualification item exceeding 70 characters (76 chars)
        String longItem = "الصحة النفسية للأطفال، تحليل الرسومات التعبيرية وتشخيص الاضطرابات الانفعالية";

        doctorUpdateDto request = createRequest(
                null,
                null,
                List.of(longItem),
                null,
                null,
                null
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("each qualification must not exceed 70 characters", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenIbanIsBlank() {

        // Create a request with a blank IBAN
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                null,
                null,
                "   "
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("iban is required", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenIbanHasLessThan22Digits() {

        // Create a request with fewer than 22 digits after SA 
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                null,
                null,
                "SA123"
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("iban must be a valid Saudi IBAN (SA followed by 22 digits)", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenIbanHasMoreThan22Digits() {

        // Create a request with more than 22 digits after SA
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                null,
                null,
                "SA12345678901234567890123"
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("iban must be a valid Saudi IBAN (SA followed by 22 digits)", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenIbanDoesNotStartWithSA() {

        // Create a request with a wrong country prefix instead of SA
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                null,
                null,
                "EG1234567890123456789012"
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("iban must be a valid Saudi IBAN (SA followed by 22 digits)", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldThrowException_whenIbanContainsLettersInDigitPart() {

        // Create a request with letters in the digit part instead of numbers only
        doctorUpdateDto request = createRequest(
                null,
                null,
                null,
                null,
                null,
                "SA1234567890ABCD12345678"
        );

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> accountService.updateDoctor(doctorId, request)
        );

        // Verify message
        assertEquals("iban must be a valid Saudi IBAN (SA followed by 22 digits)", exception.getMessage());

        // Verify repository was never called
        verifyNoInteractions(profilesRepo);
    }

    @Test
    void updateDoctorProfile_shouldReturnFailure_whenPendingQualificationRequestExists() {

        // Create a valid request with qualifications
        doctorUpdateDto request = createRequest(
                null,
                null,
                List.of("طب الأطفال", "الطب النفسي للأطفال"),
                null,
                null,
                null
        );

        // Mock repository behavior
        doThrow(new RuntimeException("لديك طلب تعديل مؤهلات قيد المراجعة حالياً."))
                .when(profilesRepo).updateDoctor(doctorId, request);

        // Call the method under test
        accountResponseDto result = accountService.updateDoctor(doctorId, request);

        // Verify repository interactions
        verify(profilesRepo).updateDoctor(doctorId, request);

        // Verify returned DTO fields
        assertNotNull(result);
        assertFalse(result.isSuccess());
        assertEquals("UPDATE_FAILED", result.getCode());
        assertEquals("لديك طلب تعديل مؤهلات قيد المراجعة حالياً.", result.getMessage());
    }
}
