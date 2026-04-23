package com.bouh.backend.service.appointments;

import com.bouh.backend.config.AgoraConfig;
import com.bouh.backend.model.Dto.appointmentDto;
import com.bouh.backend.model.Dto.Meeting.JoinMeetingResponseDto;
import com.bouh.backend.model.repository.AppointmentRepo;

import io.agora.media.RtcTokenBuilder;
import io.agora.media.RtcTokenBuilder2;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;

@Service
public class AgoraMeetingService {

    private static final ZoneId ZONE = ZoneId.of("Asia/Riyadh");

    private final AppointmentRepo appointmentRepo;
    private final AgoraConfig agoraProperties;

    public AgoraMeetingService(AppointmentRepo appointmentRepo, AgoraConfig agoraProperties) {
        this.appointmentRepo = appointmentRepo;
        this.agoraProperties = agoraProperties;
    }

    public JoinMeetingResponseDto joinAppointment(String firebaseDocUID, String appointmentId) throws Exception {
        appointmentDto appointment = appointmentRepo.findById(appointmentId);
        System.out.println("=== JOIN DEBUG BACKEND ===");
System.out.println("firebaseDocUID = " + firebaseDocUID);
System.out.println("appointmentId = " + appointmentId);

if (appointment != null) {
    System.out.println("caregiverId = " + appointment.getCaregiverId());
    System.out.println("doctorId = " + appointment.getDoctorId());
} else {
    System.out.println("appointment is NULL");
}
        if (appointment == null) {
            throw new IllegalArgumentException("الموعد غير موجود");
        }

        boolean allowedUser =
                firebaseDocUID.equals(appointment.getCaregiverId()) ||
                firebaseDocUID.equals(appointment.getDoctorId());

        if (!allowedUser) {
            throw new SecurityException("غير مصرح لك بالدخول إلى هذه الجلسة");
        }

        if (appointment.getStartDateTime() == null) {
            throw new IllegalStateException("وقت الموعد غير متوفر");
        }

        ZonedDateTime start = ZonedDateTime.ofInstant(
                Instant.ofEpochSecond(
                        appointment.getStartDateTime().getSeconds(),
                        appointment.getStartDateTime().getNanos()
                ),
                ZONE
        );

        ZonedDateTime end = start.plusMinutes(30);
        ZonedDateTime now = ZonedDateTime.now(ZONE);

        if (now.isBefore(start) || !now.isBefore(end)) {
            throw new IllegalStateException("الدخول متاح فقط أثناء وقت الموعد");
        }
appointmentRepo.markAsPresent(appointmentId);

        String channelName = "appointment_" + appointmentId;
        int uid = Math.abs(firebaseDocUID.hashCode());

    int expireTimestamp = (int) (Instant.now().getEpochSecond() + 3600);

RtcTokenBuilder builder = new RtcTokenBuilder();

String token = builder.buildTokenWithUid(
        agoraProperties.getAppId(),
        agoraProperties.getAppCertificate(),
        channelName,
        uid,
        RtcTokenBuilder.Role.Role_Publisher,
        expireTimestamp
);

        return new JoinMeetingResponseDto(
                agoraProperties.getAppId(),
                channelName,
                token,
                uid,
                appointmentId,
                "publisher"
        );
    }
}