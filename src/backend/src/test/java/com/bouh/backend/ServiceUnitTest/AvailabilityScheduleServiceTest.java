package com.bouh.backend.ServiceUnitTest;

import com.bouh.backend.config.TimeSlotConfig;
import com.bouh.backend.model.Dto.AvailabilitySchedule.*;
import com.bouh.backend.model.repository.AvailabilityScheduleRepo;
import com.bouh.backend.service.AvailabilityScheduleService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AvailabilityScheduleServiceTest {

    // SLOT_COUNT is read at test-time so tests stay correct if the flag changes.
    // Currently: AFTERNOON_SLOT_COUNT(10) + MORNING_SLOT_COUNT(2) = 12
    private static final int SLOT_COUNT = TimeSlotConfig.AFTERNOON_SLOT_COUNT; // 12
    private static final int MAX_SLOT_INDEX = SLOT_COUNT - 1; // 11

    @Mock
    private AvailabilityScheduleRepo scheduleRepo;

    @InjectMocks
    private AvailabilityScheduleService service;

    private static final String DOCTOR_ID = "N7k5KcwJqtYiuKhuEHWR8K1VaMP2";

    // Helper builders

    /** Build an AvailabilityStoredSlotDto with the given index and booked flag. */
    private AvailabilityStoredSlotDto buildSlot(int index, boolean booked) {
        AvailabilityStoredSlotDto s = new AvailabilityStoredSlotDto();
        s.setIndex(index);
        s.setBooked(booked);
        return s;
    }

    /** Build an AvailabilityDayDto where every supplied index is NOT booked. */
    private AvailabilityDayDto buildDay(String date, Integer... indexes) {
        List<AvailabilityStoredSlotDto> slots = new ArrayList<>();
        for (int idx : indexes)
            slots.add(buildSlot(idx, false));
        AvailabilityDayDto day = new AvailabilityDayDto();
        day.setDate(date);
        day.setSlots(slots);
        return day;
    }

    /** Build an AvailabilityDayDto that has exactly one slot which IS booked. */
    private AvailabilityDayDto buildDayWithBookedSlot(String date, int bookedIndex) {
        AvailabilityDayDto day = new AvailabilityDayDto();
        day.setDate(date);
        day.setSlots(List.of(buildSlot(bookedIndex, true)));
        return day;
    }

    /** Build a full update request for a single day. */
    private AvailabilityScheduleUpdateDto buildRequest(String date, Integer... indexes) {
        AvailabilityDayUpdateDto dayUpdate = new AvailabilityDayUpdateDto();
        dayUpdate.setDate(date);
        dayUpdate.setOfferedSlotIndexes(new ArrayList<>(Arrays.asList(indexes)));
        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(dayUpdate));
        return req;
    }

    // ── Date helpers
    private String today() {
        return LocalDate.now().toString();
    }

    private String tomorrow() {
        return LocalDate.now().plusDays(1).toString();
    }

    private String yesterday() {
        return LocalDate.now().minusDays(1).toString();
    }

    private String oneMonthAhead() {
        return LocalDate.now().plusMonths(1).toString();
    }

    private String twoMonthsAhead() {
        return LocalDate.now().plusMonths(2).toString();
    }

    private String beyondTwoMonths() {
        return LocalDate.now().plusMonths(2).plusDays(1).toString();
    }

    // getSchedule()

    @Test
    void getSchedule_validRange_returnsStoredAndEmptyDays() {

        String storedDate = tomorrow();
        Map<String, AvailabilityDayDto> stored = new HashMap<>();
        stored.put(storedDate, buildDay(storedDate, 0, 2, 5));

        when(scheduleRepo.getDaysInRangeMap(
                eq(DOCTOR_ID),
                eq(today()),
                eq(tomorrow())))
                .thenReturn(stored);

        AvailabilityScheduleDto result = service.getSchedule(DOCTOR_ID, today(), tomorrow());

        // today has no stored data → empty slots
        boolean hasTodayEmpty = result.getDays().stream()
                .anyMatch(d -> today().equals(d.getDate()) && d.getSlots().isEmpty());
        assertThat(hasTodayEmpty).isTrue();

        // tomorrow has stored data → slots 0, 2, 5
        boolean hasTomorrowSlots = result.getDays().stream()
                .anyMatch(d -> tomorrow().equals(d.getDate()) && d.getSlots().size() >= 3);
        assertThat(hasTomorrowSlots).isTrue();

        verify(scheduleRepo).getDaysInRangeMap(
                eq(DOCTOR_ID),
                eq(today()),
                eq(tomorrow()));
    }

    @Test
    void getSchedule_whenDayNotSet_returnsEmptyDay() {
        when(scheduleRepo.getDaysInRangeMap(any(), any(), any()))
                .thenReturn(new HashMap<>());

        AvailabilityScheduleDto result = service.getSchedule(DOCTOR_ID, today(), today());

        boolean hasEmptyDay = result.getDays().stream()
                .anyMatch(d -> today().equals(d.getDate()) && d.getSlots().isEmpty());
        assertThat(hasEmptyDay).isTrue();

        verify(scheduleRepo).getDaysInRangeMap(
                eq(DOCTOR_ID),
                eq(today()),
                eq(today()));
    }

    @Test
    void getSchedule_fromBeforeCurrentMonth_clampsToStartOfMonth() {
        when(scheduleRepo.getDaysInRangeMap(any(), any(), any()))
                .thenReturn(new HashMap<>());

        service.getSchedule(DOCTOR_ID,
                LocalDate.now().minusMonths(3).toString(), tomorrow());

        ArgumentCaptor<String> fromCaptor = ArgumentCaptor.forClass(String.class);
        verify(scheduleRepo).getDaysInRangeMap(eq(DOCTOR_ID), fromCaptor.capture(), any());

        LocalDate capturedFrom = LocalDate.parse(fromCaptor.getValue());
        assertThat(capturedFrom.getDayOfMonth()).isEqualTo(1);
        assertThat(capturedFrom.getMonth()).isEqualTo(LocalDate.now().getMonth());

        verify(scheduleRepo).getDaysInRangeMap(
                eq(DOCTOR_ID),
                fromCaptor.capture(),
                eq(tomorrow()));
    }

    @Test
    void getSchedule_toBeyondTwoMonths_clampsToMaxAllowed() {
        when(scheduleRepo.getDaysInRangeMap(any(), any(), any()))
                .thenReturn(new HashMap<>());

        service.getSchedule(DOCTOR_ID, today(),
                LocalDate.now().plusMonths(5).toString());

        ArgumentCaptor<String> toCaptor = ArgumentCaptor.forClass(String.class);
        verify(scheduleRepo).getDaysInRangeMap(eq(DOCTOR_ID), any(), toCaptor.capture());

        assertThat(LocalDate.parse(toCaptor.getValue()))
                .isEqualTo(LocalDate.now().plusMonths(2));

        verify(scheduleRepo).getDaysInRangeMap(
                eq(DOCTOR_ID),
                eq(today()),
                toCaptor.capture());
    }

    @Test
    void getSchedule_invalidDateFormat_throws() {
        assertThatThrownBy(() -> service.getSchedule(DOCTOR_ID, "01/01/2026", today()))
                .isInstanceOf(Exception.class);

        // repo should never be called if date parsing fails
        verifyNoInteractions(scheduleRepo);
    }

    // updateSchedule() – date validation

    @Test
    void updateSchedule_wrongDateFormat_throws() {
        AvailabilityDayUpdateDto day = new AvailabilityDayUpdateDto();
        day.setDate("20-02-2026"); // dd-MM-yyyy is wrong
        day.setOfferedSlotIndexes(List.of(0));
        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(day));

        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, req))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Invalid date format");

        // repo should never be called if date parsing fails
        verifyNoInteractions(scheduleRepo);

    }

    @Test
    void updateSchedule_emptyDaysList_throws() {
        // Arrange
        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(Collections.emptyList());

        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, req))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("No days provided");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_pastDate_throws() {
        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(yesterday(), 0)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot edit past dates");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_dateBeyondTwoMonths_throws() {
        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(beyondTwoMonths(), 0)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot edit beyond 2 months");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_today_accepted() {
        when(scheduleRepo.getDaysByDates(any(), any())).thenReturn(new HashMap<>());
        doNothing().when(scheduleRepo).update(any(), any(), any());

        assertThatNoException()
                .isThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(today(), 0)));

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(today())));
        verify(scheduleRepo).update(eq(DOCTOR_ID), any(), any());
    }

    @Test
    void updateSchedule_twoMonthsAhead_accepted() {
        when(scheduleRepo.getDaysByDates(any(), any())).thenReturn(new HashMap<>());
        doNothing().when(scheduleRepo).update(any(), any(), any());

        assertThatNoException()
                .isThrownBy(() -> service.updateSchedule(DOCTOR_ID,
                        buildRequest(twoMonthsAhead(), 0)));

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(twoMonthsAhead())));
        verify(scheduleRepo).update(eq(DOCTOR_ID), any(), any());
    }

    // updateSchedule() – slot index validation

    @Test
    void updateSchedule_negativeIndex_throws() {
        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(tomorrow(), -1)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("slot index out of range");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_indexEqualsSlotCount_throws() {
        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(tomorrow(), SLOT_COUNT)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("slot index out of range");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_duplicateIndexes_throws() {
        AvailabilityDayUpdateDto day = new AvailabilityDayUpdateDto();
        day.setDate(tomorrow());
        day.setOfferedSlotIndexes(new ArrayList<>(Arrays.asList(1, 3, 1))); // 1 duplicated
        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(day));

        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, req))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("duplicate slot index");

        verifyNoInteractions(scheduleRepo);
    }

    @Test
    void updateSchedule_indexZero_accepted() {
        when(scheduleRepo.getDaysByDates(any(), any())).thenReturn(new HashMap<>());
        doNothing().when(scheduleRepo).update(any(), any(), any());

        assertThatNoException()
                .isThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(tomorrow(), 0)));

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(tomorrow())));
        verify(scheduleRepo).update(eq(DOCTOR_ID), any(), any());
    }

    @Test
    void updateSchedule_indexAtUpperBoundary_accepted() {
        when(scheduleRepo.getDaysByDates(any(), any())).thenReturn(new HashMap<>());
        doNothing().when(scheduleRepo).update(any(), any(), any());

        assertThatNoException()
                .isThrownBy(() -> service.updateSchedule(DOCTOR_ID,
                        buildRequest(tomorrow(), MAX_SLOT_INDEX)));

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(tomorrow())));
        verify(scheduleRepo).update(eq(DOCTOR_ID), any(), any());
    }

    // updateSchedule() – booked-slot protection

    @Test
    void updateSchedule_removingBookedSlot_throws() {
        String date = tomorrow();
        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date, buildDayWithBookedSlot(date, 3));
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), any())).thenReturn(existing);

        // Offer only slot 1 — booked slot 3 is omitted → must throw
        assertThatThrownBy(() -> service.updateSchedule(DOCTOR_ID, buildRequest(date, 1)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot remove a booked slot")
                .hasMessageContaining("index=3");

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo, never()).update(any(), any(), any());
    }

    @Test
    void updateSchedule_bookedSlotRetainsFlag_newSlotIsFalse() {

        String date = tomorrow();
        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date, buildDayWithBookedSlot(date, 2));
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date))))
                .thenReturn(existing);

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        service.updateSchedule(DOCTOR_ID, buildRequest(date, 2, 4));

        List<AvailabilityStoredSlotDto> saved = writeCaptor.getValue().get(date).getSlots();

        AvailabilityStoredSlotDto slot2 = saved.stream()
                .filter(s -> s.getIndex() == 2).findFirst().orElseThrow();
        assertThat(slot2.isBooked()).isTrue();

        AvailabilityStoredSlotDto slot4 = saved.stream()
                .filter(s -> s.getIndex() == 4).findFirst().orElseThrow();
        assertThat(slot4.isBooked()).isFalse();

        // verify delete set is empty — slots 2 and 4 were offered, nothing to delete
        assertThat(deleteCaptor.getValue()).isEmpty();

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

    // updateSchedule() – delete-on-empty logic

    @Test
    void updateSchedule_emptyIndexes_deletesOneFromExistingDocs() {

        String date1 = tomorrow();
        String date2 = oneMonthAhead();

        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date1, buildDay(date1, 0, 2, 5)); // doctor clears this one
        existing.put(date2, buildDay(date2, 1, 3)); // this one is untouched

        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date1))))
                .thenReturn(existing);

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        AvailabilityDayUpdateDto day = new AvailabilityDayUpdateDto();
        day.setDate(date1);
        day.setOfferedSlotIndexes(new ArrayList<>()); // empty → delete only date1
        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(day));

        service.updateSchedule(DOCTOR_ID, req);

        assertThat(deleteCaptor.getValue()).contains(date1);
        assertThat(deleteCaptor.getValue()).doesNotContain(date2);

        assertThat(writeCaptor.getValue()).isEmpty();

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date1)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

    @Test
    void updateSchedule_multipleEmptyIndexes_existingDocs_multipleDatesDeleted() {

        String date1 = tomorrow();
        String date2 = oneMonthAhead();

        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date1, buildDay(date1, 0, 2));
        existing.put(date2, buildDay(date2, 1, 3));

        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), any()))
                .thenReturn(existing);

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        AvailabilityDayUpdateDto d1 = new AvailabilityDayUpdateDto();
        d1.setDate(date1);
        d1.setOfferedSlotIndexes(new ArrayList<>()); // empty → delete

        AvailabilityDayUpdateDto d2 = new AvailabilityDayUpdateDto();
        d2.setDate(date2);
        d2.setOfferedSlotIndexes(new ArrayList<>()); // empty → delete

        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(d1, d2));

        service.updateSchedule(DOCTOR_ID, req);

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), any());
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());

        assertThat(deleteCaptor.getValue()).contains(date1, date2);

        assertThat(writeCaptor.getValue()).isEmpty();
    }

    // updateSchedule() – successful write paths

    @Test
    void updateSchedule_writeOneSlot_noExistingDoc() {
        String date = tomorrow();
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date))))
                .thenReturn(new HashMap<>());

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        service.updateSchedule(DOCTOR_ID, buildRequest(date, 3));

        List<AvailabilityStoredSlotDto> slots = writeCaptor.getValue().get(date).getSlots();
        assertThat(slots).hasSize(1);
        assertThat(slots.get(0).getIndex()).isEqualTo(3);
        assertThat(slots.get(0).isBooked()).isFalse();
        assertThat(deleteCaptor.getValue()).isEmpty();

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

    @Test
    void updateSchedule_writeOneSlot_existingDoc() {
        String date = tomorrow();
        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date, buildDay(date, 0));
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date))))
                .thenReturn(existing);

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        service.updateSchedule(DOCTOR_ID, buildRequest(date, 0, 3));

        List<AvailabilityStoredSlotDto> slots = writeCaptor.getValue().get(date).getSlots();
        assertThat(slots).hasSize(2);
        assertThat(slots).extracting(AvailabilityStoredSlotDto::getIndex)
                .containsExactlyInAnyOrder(0, 3);
        assertThat(slots).allMatch(s -> !s.isBooked());
        assertThat(deleteCaptor.getValue()).isEmpty();

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

    @Test
    void updateSchedule_writeMultipleSlots_noExistingDoc() {
        String date = tomorrow();
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date))))
                .thenReturn(new HashMap<>());

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        service.updateSchedule(DOCTOR_ID, buildRequest(date, 0, 5, MAX_SLOT_INDEX));

        List<AvailabilityStoredSlotDto> slots = writeCaptor.getValue().get(date).getSlots();
        assertThat(slots).hasSize(3);
        assertThat(slots).extracting(AvailabilityStoredSlotDto::getIndex)
                .containsExactlyInAnyOrder(0, 5, MAX_SLOT_INDEX);
        assertThat(slots).allMatch(s -> !s.isBooked());
        assertThat(deleteCaptor.getValue()).isEmpty();

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

    @Test
    void updateSchedule_writeMultipleSlots_existingDoc() {
        String date = tomorrow();
        Map<String, AvailabilityDayDto> existing = new HashMap<>();
        existing.put(date, buildDay(date, 0, 1));
        when(scheduleRepo.getDaysByDates(eq(DOCTOR_ID), eq(List.of(date))))
                .thenReturn(existing);

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(eq(DOCTOR_ID), writeCaptor.capture(), deleteCaptor.capture());

        service.updateSchedule(DOCTOR_ID, buildRequest(date, 0, 1, 3, 5, 7));

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), eq(List.of(date)));
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());

        List<AvailabilityStoredSlotDto> slots = writeCaptor.getValue().get(date).getSlots();
        assertThat(slots).hasSize(5);
        assertThat(slots).extracting(AvailabilityStoredSlotDto::getIndex)
                .containsExactlyInAnyOrder(0, 1, 3, 5, 7);
        assertThat(slots).allMatch(s -> !s.isBooked());
        assertThat(deleteCaptor.getValue()).isEmpty();
    }

    // updateSchedule() – mixed write + delete in one request

    @Test
    void updateSchedule_mixedRequest_writesAndDeletes() {
        String writeDate = tomorrow();
        String deleteDate = oneMonthAhead();

        when(scheduleRepo.getDaysByDates(any(), any())).thenReturn(new HashMap<>());

        ArgumentCaptor<Map<String, AvailabilityDayDto>> writeCaptor = ArgumentCaptor.captor();
        ArgumentCaptor<Set<String>> deleteCaptor = ArgumentCaptor.captor();
        doNothing().when(scheduleRepo).update(any(), writeCaptor.capture(), deleteCaptor.capture());

        AvailabilityDayUpdateDto dWrite = new AvailabilityDayUpdateDto();
        dWrite.setDate(writeDate);
        dWrite.setOfferedSlotIndexes(new ArrayList<>(List.of(0)));

        AvailabilityDayUpdateDto dDelete = new AvailabilityDayUpdateDto();
        dDelete.setDate(deleteDate);
        dDelete.setOfferedSlotIndexes(new ArrayList<>()); // empty → delete

        AvailabilityScheduleUpdateDto req = new AvailabilityScheduleUpdateDto();
        req.setDays(List.of(dWrite, dDelete));

        service.updateSchedule(DOCTOR_ID, req);

        assertThat(writeCaptor.getValue()).containsKey(writeDate);
        assertThat(deleteCaptor.getValue()).contains(deleteDate);

        verify(scheduleRepo).getDaysByDates(eq(DOCTOR_ID), any());
        verify(scheduleRepo).update(DOCTOR_ID, writeCaptor.getValue(), deleteCaptor.getValue());
    }

}