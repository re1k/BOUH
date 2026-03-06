package com.bouh.backend.service.payment;

import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.doctorDto;
import com.bouh.backend.model.Dto.payment.RefundRequestDto;
import com.bouh.backend.model.Dto.payment.RefundResponseDto;
import com.bouh.backend.model.repository.AppointmentRepo;
import com.bouh.backend.model.repository.caregiverRepo;
import com.bouh.backend.model.repository.doctorRepo;
import com.bouh.backend.service.notification.NotificationService;
import com.google.cloud.Timestamp;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.model.Refund;
import com.stripe.param.RefundCreateParams;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import org.springframework.stereotype.Service;

@Service
public class RefundService {

    // Use the same timezone as the rest of the appointment logic for date comparison.
    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");

    private final AppointmentRepo appointmentRepo;
    private final caregiverRepo caregiverRepository;
    private final doctorRepo doctorRepo;
    private final NotificationService notificationService;

    // Inject repos and notification service so we can look up appointment/doctor and send FCM.
    public RefundService(AppointmentRepo appointmentRepo, caregiverRepo caregiverRepository, doctorRepo doctorRepo,
            NotificationService notificationService) {
        this.appointmentRepo = appointmentRepo;
        this.caregiverRepository = caregiverRepository;
        this.doctorRepo = doctorRepo;
        this.notificationService = notificationService;
    }

    public RefundResponseDto refund(RefundRequestDto request, String uid) {
        try {


            // Notify the other party (caregiver or doctor) that the appointment was canceled
            notifyOtherPartyAboutCanceledAppointment(request.getPaymentIntentId(), uid);


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


            return new RefundResponseDto(
                    refund.getId(),
                    refund.getStatus(),
                    refund.getAmount(),
                    refund.getCurrency());

        } catch (StripeException e) {
            throw new RuntimeException("Stripe refund error: " + e.getMessage(), e);
        }
    }

    // Notify caregiver (if doctor canceled) or doctor (if caregiver canceled and appointment is today)
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

        String timeText = appointmentDateTime.toLocalTime().format(DateTimeFormatter.ofPattern("h:mm a"));

        // If doctor canceled, notify caregiver no matter what day it is.
        if (actorUid.equals(doctorId)) {
            // Get caregiver from repo; caregiverDto holds fcmToken
            var caregiver = caregiverRepository.findByUid(caregiverId);
            String caregiverToken = caregiver == null ? null : caregiver.getFcmToken();
            if (caregiverToken == null || caregiverToken.isBlank()) {
                return;
            }

            notificationService.sendNotification(
                    caregiverToken,
                    "تم إلغاء موعد الساعة " + timeText,
                    "تم إلغاء الموعد من قبل الطبيب.");
            return;
        }

        // If caregiver canceled, notify doctor only if the appointment is today.
        if (actorUid.equals(caregiverId)) {
            if (!today.equals(appointmentDate)) {
                return;
            }

            doctorDto doctor = doctorRepo.findByUid(doctorId);
            if (doctor == null || doctor.getFcmToken() == null || doctor.getFcmToken().isBlank()) {
                return;
            }

            notificationService.sendNotification(
                    doctor.getFcmToken(),
                    "تم إلغاء موعد الساعة " + timeText,
                    "تم إلغاء الموعد من قبل مقدم الرعاية.");
        }
    }

}
