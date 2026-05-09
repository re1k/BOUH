package com.bouh.backend.ServiceUnitTest;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

import java.time.LocalDate;

import com.bouh.backend.model.Dto.ChildRequestDto;
import com.bouh.backend.model.Dto.childDto;
import com.bouh.backend.model.repository.childrenRepo;
import com.bouh.backend.service.ChildrenService;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
public class AddChildUnitTest {

    @Mock
    private childrenRepo childrenRepo;

    @InjectMocks
    private ChildrenService childrenService;

    // Shared caregiver ID used in all test cases
    private final String caregiverId = "eFXGJMjrouTwE3uj0FaVAS6evAf2";

    // Helper method to quickly create ChildRequestDto objects
    private ChildRequestDto createRequest(
            String name,
            String dateOfBirth,
            String gender
    ) {
        ChildRequestDto request = new ChildRequestDto();
        request.setName(name);
        request.setDateOfBirth(dateOfBirth);
        request.setGender(gender);
        return request;
    }

        @Test
        void addChild_shouldAddChildSuccessfully_whenAllInputsAreValid() throws Exception {

                // Create a valid child request
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-01-01",
                        "female"
                );

                // Create expected returned DTO
                childDto expectedChild = new childDto();
                expectedChild.setChildID("WE8KKe5i1G78NUUUI4tB");
                expectedChild.setName("Loba");
                expectedChild.setDateOfBirth(LocalDate.of(2015, 1, 1));
                expectedChild.setGender("female");
                expectedChild.setDrawings(List.of());

                // Mock repository behavior
                when(childrenRepo.countChildren(caregiverId)).thenReturn(1);

                when(childrenRepo.addChild(caregiverId,"Loba","2015-01-01","female")).thenReturn(expectedChild);

                // Call the method under test
                childDto result = childrenService.addChild(caregiverId, request);

                // Verify repository interactions
                verify(childrenRepo).countChildren(caregiverId);

                verify(childrenRepo).addChild(caregiverId,"Loba","2015-01-01","female");

                // Verify returned DTO fields
                assertNotNull(result);
                assertEquals("WE8KKe5i1G78NUUUI4tB", result.getChildID());
                assertEquals("Loba", result.getName());
                assertEquals(LocalDate.of(2015, 1, 1), result.getDateOfBirth());
                assertEquals("female", result.getGender());
                assertEquals(List.of(), result.getDrawings());
                }

        @Test 
        void addChild_shouldThrowException_whenNameIsEmpty() {

                // Create request with empty name
                ChildRequestDto request = createRequest(
                        "     ",
                        "2015-01-01",
                        "male"
                );

                // Verify exception
                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                // Verify message
                assertEquals("name is required",exception.getMessage());
                
                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldThrowException_whenNameExceedsTenCharacters() {

                // Create request with long name
                ChildRequestDto request = createRequest(
                        "VeryLongName11",
                        "2015-01-01",
                        "male"
                );

                // Verify exception
                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                // Verify message
                assertEquals("name must not exceed 10 characters",exception.getMessage());

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldThrowException_whenNameContainsSpecialCharacters() {

                // Create request with invalid special character
                ChildRequestDto request = createRequest(
                        "Loba@",
                        "2015-01-01",
                        "female"
                );

                // Verify exception
                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                // Verify message
                assertEquals("name cannot contain special characters", exception.getMessage());
                
                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldAcceptArabicEnglishNumbersAndSpacesInName() throws Exception {

                // Create request with Arabic, English, numbers, and spaces
                ChildRequestDto request = createRequest(
                        "علي Loba1",
                        "2015-01-01",
                        "female"
                );

                childDto expectedChild = new childDto();
                expectedChild.setChildID("WE8KKe5i1G78NUUUI4tB");
                expectedChild.setName("علي Loba1");
                expectedChild.setDateOfBirth(LocalDate.of(2015, 1, 1));
                expectedChild.setGender("female");
                expectedChild.setDrawings(List.of());

                // Mock repository behavior
                when(childrenRepo.countChildren(caregiverId))
                        .thenReturn(1);

                when(childrenRepo.addChild(caregiverId,"علي Loba1","2015-01-01","female")).thenReturn(expectedChild);

                // Call service
                childDto result = childrenService.addChild(caregiverId, request);

                // Verify repository interaction
                verify(childrenRepo).addChild(caregiverId,"علي Loba1","2015-01-01","female");

                // Verify returned result
                assertNotNull(result);
        }

        @Test
        void addChild_shouldNormalizeMultipleSpacesInName() throws Exception {

                // Name contains multiple spaces
                ChildRequestDto request = createRequest(
                        "   lo      ba   ",
                        "2015-01-01",
                        "female"
                );

                childDto expectedChild = new childDto();
                expectedChild.setChildID("WE8KKe5i1G78NUUUI4tB");
                expectedChild.setName("lo ba");
                expectedChild.setDateOfBirth(LocalDate.of(2015, 1, 1));
                expectedChild.setGender("female");
                expectedChild.setDrawings(List.of());

                when(childrenRepo.countChildren(caregiverId)).thenReturn(1);

                when(childrenRepo.addChild(caregiverId,"lo ba", "2015-01-01","female")).thenReturn(expectedChild);

                // Call service
                childrenService.addChild(caregiverId, request);

                // Verify spaces were normalized correctly
                verify(childrenRepo).addChild(caregiverId,"lo ba","2015-01-01","female");
        }

        @Test 
        void addChild_shouldThrowException_whenDateOfBirthIsEmpty() {

                // Create request with empty DOB
                ChildRequestDto request = createRequest("Loba","   ","female");

                // Verify exception
                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("dateOfBirth is required",exception.getMessage());

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test 
        void addChild_shouldThrowException_whenDateFormatIsInvalid() {

                // Create request with invalid date format
                ChildRequestDto request = createRequest("Loba","01-01-2015","female");

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("dateOfBirth must be YYYY-MM-DD and valid date.",exception.getMessage());

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldThrowException_whenDayValueIsInvalid() {

                // Invalid day value greater than maximum possible days
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-03-40",
                        "female"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals(
                        "dateOfBirth must be YYYY-MM-DD and valid date.",
                        exception.getMessage()
                );

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
                }

        @Test
        void addChild_shouldThrowException_whenMonthValueIsInvalid() {

                // Invalid month value greater than 12
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-15-01",
                        "female"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals(
                        "dateOfBirth must be YYYY-MM-DD and valid date.",
                        exception.getMessage()
                );

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
                }

        @Test
        void addChild_shouldThrowException_whenDateCombinationIsInvalid() {

                // February 30th can never exist
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-02-30",
                        "female"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals(
                        "dateOfBirth must be YYYY-MM-DD and valid date.",
                        exception.getMessage()
                );

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
                }

        @Test
        void addChild_shouldThrowException_whenChildAgeIsLessThanSix() {

                // Child too young
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2023-01-01",
                        "female"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("Child age must be between 6 and 13 years.",exception.getMessage());
                
                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldThrowException_whenChildAgeIsGreaterThanThirteen() {

                // Child too old
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2010-01-01",
                        "female"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("Child age must be between 6 and 13 years.",exception.getMessage());

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test 
        void addChild_shouldThrowException_whenGenderIsEmpty() {

                // Empty gender
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-01-01",
                        "   "
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("gender is required",exception.getMessage());
                
                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test 
        void addChild_shouldThrowException_whenGenderIsInvalid() {

                // Invalid gender
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-01-01",
                        "unknown"
                );

                IllegalArgumentException exception = assertThrows(
                        IllegalArgumentException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("gender must be male/female",exception.getMessage());

                // Verify repository was never called
                verifyNoInteractions(childrenRepo);
        }

        @Test
        void addChild_shouldThrowException_whenCaregiverAlreadyHasFiveChildren() throws Exception {

                // Create valid request
                ChildRequestDto request = createRequest(
                        "Loba",
                        "2015-01-01",
                        "female"
                );

                // Mock caregiver already having 5 children
                when(childrenRepo.countChildren(caregiverId))
                        .thenReturn(5);

                // Verify exception
                IllegalStateException exception = assertThrows(
                        IllegalStateException.class,
                        () -> childrenService.addChild(caregiverId, request)
                );

                assertEquals("You can only add up to 5 children.",exception.getMessage());

                verify(childrenRepo).countChildren(caregiverId);

                // Verify repository was never called to add child
                verify(childrenRepo, never()).addChild(
                        anyString(),
                        anyString(),
                        anyString(),
                        anyString()
                );
        }
}