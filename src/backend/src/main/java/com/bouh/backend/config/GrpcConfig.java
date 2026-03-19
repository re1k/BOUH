package com.bouh.backend.config;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;

import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GrpcConfig {
    /*
     *
     * Creates a gRPC connection channel between the backend
     * and the Triton inference server.
     * keeps it alive for paralell request and less netork latncy
     *
     * host : google cloud run server hostname
     */

    @Bean
    public ManagedChannel channel(@Value("${triton.host}") String host) {
        return ManagedChannelBuilder
                .forTarget(host)
                .keepAliveTime(30, TimeUnit.SECONDS)
                .keepAliveWithoutCalls(true)
                .build();
    }
}