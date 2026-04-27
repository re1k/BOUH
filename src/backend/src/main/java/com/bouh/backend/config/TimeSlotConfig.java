package com.bouh.backend.config;

import java.time.LocalTime;

/**
 * This class defines the fixed time slot rules for the whole Bouh system.
 * All doctors share the same time range (4 PM -> 9 PM).
 *
 * It is used by:
 * - AvailabilityService
 * - AppointmentService (booking)
 * - Cancellation logic
 *
 * It prevents slot index mistakes.
 */
public final class TimeSlotConfig {

    public static final LocalTime START_TIME = LocalTime.of(16, 0); // 4:00 PM
    public static final LocalTime END_TIME   = LocalTime.of(21, 0); // 9:00 PM

    public static final int SLOT_MINUTES = 30;

    // 5 hours = 300 minutes / 30 = 10 slots
    public static final int AFTERNOON_SLOT_COUNT = 10;

    // Morning test slots for demo
    public static final boolean MORNING_SLOTS_ENABLED = true; //if we do not want just make it false
    public static final LocalTime MORNING_START = LocalTime.of(9, 0); //we can change later depending on when is the demo
    public static final int MORNING_SLOT_COUNT = 2; // 13:00–13:30, 13:30–14:00

    public static final int SLOT_COUNT = AFTERNOON_SLOT_COUNT + 
        (MORNING_SLOTS_ENABLED ? MORNING_SLOT_COUNT : 0);

    private TimeSlotConfig() {}

    public static boolean isMorningSlot(int slotIndex) {
        return MORNING_SLOTS_ENABLED && slotIndex >= AFTERNOON_SLOT_COUNT; // >= because I will make the morning index 11, 12 and so on after the actual ones we have
    }

    public static LocalTime slotStart(int slotIndex) {
        if (isMorningSlot(slotIndex)) {
            int morningIndex = slotIndex - AFTERNOON_SLOT_COUNT;
            return MORNING_START.plusMinutes((long) morningIndex * SLOT_MINUTES);
        }
        return START_TIME.plusMinutes((long) slotIndex * SLOT_MINUTES); 
    }

    public static LocalTime slotEnd(int slotIndex) {
        return slotStart(slotIndex).plusMinutes(SLOT_MINUTES); //start + 30 minutes
    }

    // Find which slot (0–9) has this start time. Returns -1 if no match.
    public static int getSlotIndexForStartTime(LocalTime time) {
        if (time == null) return -1;
        for (int i = 0; i < SLOT_COUNT; i++) {
            if (slotStart(i).equals(time)) return i;
        }
        return -1;
    }

    // Parse slot index string (0–9). Returns -1 if missing or invalid.
    public static int parseSlotIndex(String slotIndexStr) {
        if (slotIndexStr == null || slotIndexStr.isBlank()) return -1;
        try {
            int idx = Integer.parseInt(slotIndexStr.trim());
            return (idx >= 0 && idx < SLOT_COUNT) ? idx : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}
