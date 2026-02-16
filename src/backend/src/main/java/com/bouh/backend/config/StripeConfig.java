package com.bouh.backend.config;

import com.stripe.Stripe;
import io.github.cdimascio.dotenv.Dotenv;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StripeConfig {

    @Value("${stripe.secretKey:}")
    private String secretKeyFromProps;

    @PostConstruct
    public void init() {

        String finalKey = secretKeyFromProps;

        if (finalKey == null || finalKey.isBlank()) {

            Dotenv dotenv = Dotenv.configure()
                    .directory("./")
                    .ignoreIfMissing()
                    .load();

            finalKey = dotenv.get("STRIPE_SECRET_KEY");

            System.out.println("From Dotenv = " + finalKey);
        }

        if (finalKey == null || finalKey.isBlank()) {
            throw new RuntimeException("STRIPE_SECRET_KEY not found in env vars or .env file");
        }

        Stripe.apiKey = finalKey;

    }
}
