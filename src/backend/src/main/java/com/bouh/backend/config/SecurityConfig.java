package com.bouh.backend.config;

import com.bouh.backend.security.AdminAuthFilter;
import com.bouh.backend.security.FirebaseAuthFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration // Marks this class as a Spring Security configuration class
public class SecurityConfig {

    /**
     * Defines the Security Filter Chain.
     * This tells Spring Security HOW to handle incoming HTTP requests.
     */
    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            FirebaseAuthFilter firebaseAuthFilter,
            AdminAuthFilter adminAuthFilter) throws Exception {

        http
                // Disable CSRF protection
                // CSRF is only needed for browser-based apps using sessions and forms.
                // Since this is a REST API + mobile app (stateless), we disable it.
                .cors(cors -> {}) // For admin
                .csrf(csrf -> csrf.disable())

                // Define authorization rules for HTTP requests
                .authorizeHttpRequests(auth -> auth

                        // Any request that matches /api/auth/**
                        // MUST be authenticated (a valid JWT must be provided)
                        .requestMatchers("/api/accounts/**").authenticated()
                        .requestMatchers("/api/admin/**").authenticated()

                        // Classifier test endpoint (remove after testing)
                        .requestMatchers("/api/classification/**").permitAll()

                        // Any other request must also be authenticated
                        .anyRequest().authenticated()
                )

                // Register our custom Firebase authentication filter
                // This filter runs BEFORE Spring's default authentication filter
                // It verifies the Firebase JWT and sets the authenticated user
                .addFilterBefore(
                        firebaseAuthFilter,
                        UsernamePasswordAuthenticationFilter.class
                )
                // AdminAuthFilter runs after: checks admins collection for /api/admin/** requests
                .addFilterAfter(
                        adminAuthFilter,
                        FirebaseAuthFilter.class
                );

        // Build and return the security filter chain
        return http.build();
    }
}

