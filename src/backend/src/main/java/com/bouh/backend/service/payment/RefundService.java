package com.bouh.backend.service.payment;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.payment.RefundRequestDto;
import com.bouh.backend.model.Dto.payment.RefundResponseDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.google.cloud.Timestamp;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.model.Refund;
import com.stripe.param.RefundCreateParams;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.time.LocalTime;


@Slf4j
@Service
public class RefundService {

    // Use the same timezone as the rest of the appointment logic for date comparison.
    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");

    private final AppointmentRepo appointmentRepo;
    private final HttpClient httpClient;

    // Cloud function URL.
    @Value("${bouh.cloud-function.cancellation-url:}")
    private String cancellationFunctionUrl;

    public RefundService(AppointmentRepo appointmentRepo) {
        this.appointmentRepo = appointmentRepo;
        this.httpClient = HttpClient.newHttpClient();
    }

    public RefundResponseDto refund(RefundRequestDto request, String uid) {
        try {

            // 1) Retrieve PaymentIntent
            PaymentIntent intent = PaymentIntent.retrieve(request.getPaymentIntentId());

            // 2) Refund is done on the Charge
            String chargeId = intent.getLatestCharge();
            if (chargeId == null || chargeId.isBlank()) {
                throw new RuntimeException("Cannot refund: PaymentIntent has no latest_charge (not succeeded yet).");
            }

            // 3) Build refund params
            RefundCreateParams.Builder builder = RefundCreateParams.builder()
                    .setCharge(chargeId);

            // Partial refund if amount provided
            if (request.getAmount() != null) {
                builder.setAmount(request.getAmount());
            }

            Refund refund = Refund.create(builder.build());

            // Notify the other party (caregiver or doctor) that the appointment was canceled.
            notifyOtherPartyAboutCanceledAppointment(request.getPaymentIntentId(), uid);

            return new RefundResponseDto(
                    refund.getId(),
                    refund.getStatus(),
                    refund.getAmount(),
                    refund.getCurrency());

        } catch (StripeException e) {
            throw new RuntimeException("Stripe refund error: " + e.getMessage(), e);
        }
    }

    private void notifyOtherPartyAboutCanceledAppointment(String paymentIntentId, String actorUid) {
        if (paymentIntentId == null || paymentIntentId.isBlank() || actorUid == null || actorUid.isBlank()) {
            return;
        }

        appointmentDto appointment = appointmentRepo.findByPaymentIntentId(paymentIntentId);
        if (appointment == null) {
            return;
        }

        String caregiverId = appointment.getCaregiverId();
        String doctorId = appointment.getDoctorId();

        if (caregiverId == null || caregiverId.isBlank() || doctorId == null || doctorId.isBlank()) {
            return;
        }

        Timestamp startTimestamp = appointment.getStartDateTime();
        if (startTimestamp == null) {
            return;
        }

        ZonedDateTime appointmentDateTime = startTimestamp.toDate().toInstant().atZone(ZONE);
        LocalDate appointmentDate = appointmentDateTime.toLocalDate();
        LocalDate today = ZonedDateTime.now(ZONE).toLocalDate();

        // Format time, e.g. "5:30 مساءً" 
        LocalTime appointmentTime = appointmentDateTime.toLocalTime();
        String amPm = appointmentTime.getHour() < 12 ? "صباحًا" : "مساءً";
        String timeText = appointmentTime.format(DateTimeFormatter.ofPattern("h:mm")) + " " + amPm;
        // Case A: (Doctor canceled) notify caregiver 
        // Build full label: "يوم الأحد 14 مايو الساعة 5:30 مساءً"
        if (actorUid.equals(doctorId)) {
            String dayName = arabicDayName(appointmentDateTime.getDayOfWeek().getValue());
            int dayOfMonth = appointmentDateTime.getDayOfMonth();
            String monthName = arabicMonthName(appointmentDateTime.getMonthValue());
            String fullLabel = "يوم " + dayName + " " + dayOfMonth + " " + monthName + " الساعة " + timeText;
            callCancellationFunction(caregiverId, "caregiver", "doctor_canceled", fullLabel);
            return;
        }

        // Case B: (Caregiver canceled) notify doctor ONLY if appointment is today
        if (actorUid.equals(caregiverId)) {
            if (!today.equals(appointmentDate)) {
                return;
            }
            callCancellationFunction(doctorId, "doctor", "caregiver_canceled", timeText);
        }
    }

    private void callCancellationFunction(String targetUserId, String targetRole,
                                          String notificationType, String appointmentStartTime) {
        if (cancellationFunctionUrl == null || cancellationFunctionUrl.isBlank()) {
            log.warn("Cancellation cloud function URL not configured, skipping notification.");
            return;
        }

        // Build the JSON payload that the cloud function expects
        String json = String.format(
                "{\"targetUserId\":\"%s\",\"targetRole\":\"%s\",\"notificationType\":\"%s\",\"appointmentStartTime\":\"%s\"}",
                targetUserId, targetRole, notificationType, appointmentStartTime);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(cancellationFunctionUrl))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();

        // Send asynchronously so the refund response is not delayed
        httpClient.sendAsync(request, HttpResponse.BodyHandlers.ofString())
                .thenAccept(resp -> log.info("Cloud function responded: {} {}", resp.statusCode(), resp.body()))
                .exceptionally(ex -> {
                    log.error("Failed to call cancellation cloud function: {}", ex.getMessage());
                    return null;
                });
    }

    private static String arabicDayName(int isoDow) {
        return switch (isoDow) {
            case 1 -> "الأثنين";
            case 2 -> "الثلاثاء";
            case 3 -> "الأربعاء";
            case 4 -> "الخميس";
            case 5 -> "الجمعة";
            case 6 -> "السبت";
            case 7 -> "الأحد";
            default -> "";
        };
    }

    private static String arabicMonthName(int month) {
        return switch (month) {
            case 1  -> "يناير";
            case 2  -> "فبراير";
            case 3  -> "مارس";
            case 4  -> "أبريل";
            case 5  -> "مايو";
            case 6  -> "يونيو";
            case 7  -> "يوليو";
            case 8  -> "أغسطس";
            case 9  -> "سبتمبر";
            case 10 -> "أكتوبر";
            case 11 -> "نوفمبر";
            case 12 -> "ديسمبر";
            default -> "";
        };
    }

}
