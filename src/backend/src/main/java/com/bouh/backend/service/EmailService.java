package com.bouh.backend.service;

import jakarta.mail.internet.MimeMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendAccountDeletionEmail(String toEmail, String name) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, false, "UTF-8");
            helper.setFrom(fromEmail, "Bouh بوح");
            helper.setTo(toEmail);
            helper.setSubject("تم حذف حسابك");
            helper.setText(
                    "<div dir='rtl' style='text-align: right; font-family: Arial, sans-serif;'>" +
                            "<p>مرحبًا " + name + "،</p>" +
                            "<p>نود إعلامك بأنه تم حذف حسابك من تطبيق بوح من قبل المسؤول.</p>" +
                            "<p>إذا كان لديك أي استفسار، يرجى التواصل معنا.</p>" +
                            "<p>فريق بوح</p>" +
                            "</div>",
                    true);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.error("Failed to send account deletion email to {}: {}", toEmail, e.getMessage());
        }
    }

    public void sendRegistrationAcceptedEmail(String toEmail, String name) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, false, "UTF-8");
            helper.setFrom(fromEmail, "Bouh بوح");
            helper.setTo(toEmail);
            helper.setSubject(" قبول طلب التسجيل");
            helper.setText(
                    "<div dir='rtl' style='text-align: right; font-family: Arial, sans-serif;'>" +
                            "<p>مرحبًا " + name + "،</p>" +
                            "<p>يسعدنا إعلامك بأنه تم قبول طلب تسجيلك في تطبيق بوح.</p>" +
                            "<p>يمكنك الآن تسجيل الدخول والبدء في استخدام التطبيق.</p>" +
                            "<p>فريق بوح</p>" +
                            "</div>",
                    true);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.error("Failed to send registration accepted email to {}: {}", toEmail, e.getMessage());
        }
    }

    public void sendRegistrationRejectedEmail(String toEmail, String name) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, false, "UTF-8");
            helper.setFrom(fromEmail, "Bouh بوح");
            helper.setTo(toEmail);
            helper.setSubject(" رفض طلب التسجيل ");
            helper.setText(
                    "<div dir='rtl' style='text-align: right; font-family: Arial, sans-serif;'>" +
                            "<p>مرحبًا " + name + "،</p>" +
                            "<p>نأسف لإعلامك بأنه تم رفض طلب تسجيلك في تطبيق بوح.</p>" +
                            "<p>إذا كان لديك أي استفسار، يرجى التواصل معنا.</p>" +
                            "<p>فريق بوح</p>" +
                            "</div>",
                    true);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.error("Failed to send registration rejected email to {}: {}", toEmail, e.getMessage());
        }
    }

    public void sendQualificationAcceptedEmail(String toEmail, String name) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, false, "UTF-8");
            helper.setFrom(fromEmail, "Bouh بوح");
            helper.setTo(toEmail);
            helper.setSubject("تم قبول طلب تحديث المؤهلات");
            helper.setText(
                    "<div dir='rtl' style='text-align: right; font-family: Arial, sans-serif;'>" +
                            "<p>مرحبًا " + name + "،</p>" +
                            "<p>يسعدنا إعلامك بأنه تم قبول طلب تحديث مؤهلاتك في تطبيق بوح.</p>" +
                            "<p>تم تحديث ملفك الشخصي بالمؤهلات الجديدة.</p>" +
                            "<p>فريق بوح</p>" +
                            "</div>",
                    true);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.error("Failed to send qualification accepted email to {}: {}", toEmail, e.getMessage());
        }
    }

    public void sendQualificationRejectedEmail(String toEmail, String name) {
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, false, "UTF-8");
            helper.setFrom(fromEmail, "Bouh بوح");
            helper.setTo(toEmail);
            helper.setSubject("رفض طلب تحديث المؤهلات");
            helper.setText(
                    "<div dir='rtl' style='text-align: right; font-family: Arial, sans-serif;'>" +
                            "<p>مرحبًا " + name + "،</p>" +
                            "<p>نأسف لإعلامك بأنه تم رفض طلب تحديث مؤهلاتك في تطبيق بوح.</p>" +
                            "<p>إذا كان لديك أي استفسار، يرجى التواصل معنا.</p>" +
                            "<p>فريق بوح</p>" +
                            "</div>",
                    true);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.error("Failed to send qualification rejected email to {}: {}", toEmail, e.getMessage());
        }
    }

}
