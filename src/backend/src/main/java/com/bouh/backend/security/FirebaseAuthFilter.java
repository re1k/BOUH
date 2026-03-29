package com.bouh.backend.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

@Slf4j
@Component // Registers this filter as a Spring-managed component
public class FirebaseAuthFilter extends OncePerRequestFilter {

    // remove this (after testing)
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return path.startsWith("/api/classification/")
                || path.equals("/api/admin/forgot-password");
    }

    /**
     * This method is executed ONCE for every incoming HTTP request.
     * It runs BEFORE the request reaches any Controller.
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        // For admin
        // CORS preflight requests (OPTIONS) carry no Bearer token;
        // let them through so CorsConfig can add the required headers.
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        // Read the Authorization header from the HTTP request
        String header = request.getHeader("Authorization");

        // Check that the Authorization header exists
        // and follows the "Bearer <token>" format
        if (header != null && header.startsWith("Bearer ")) {

            // Extract the JWT by removing the "Bearer " prefix
            String token = header.substring(7);

            try {
                // Verify the Firebase ID Token:
                // - validates the signature
                // - checks expiration
                // - confirms it was issued by Firebase
                FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);

                // Extract the Firebase user ID (UID) from the token
                String uid = decodedToken.getUid();

                // Create a Spring Security Authentication object
                // This tells Spring that the user is successfully authenticated
                Authentication authentication = new UsernamePasswordAuthenticationToken(
                        uid, // principal (user identity)
                        null, // credentials (not needed)
                        List.of(new SimpleGrantedAuthority("ROLE_USER")) // authorities/roles (none for now)
                );

                // Store the Authentication in the SecurityContext
                // After this, controllers can access the authenticated user
                SecurityContextHolder
                        .getContext()
                        .setAuthentication(authentication);

            } catch (FirebaseAuthException e) {
                // Token is invalid, expired, or not issued by Firebase
                // Respond with HTTP 401 Unauthorized
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return; // Stop request processing
            }
        }
        if (header == null || !header.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }
        log.info("FirebaseAuthFilter hit");

        // Continue the filter chain:
        // - next filters
        // - then the Controller
        filterChain.doFilter(request, response);
    }
}
