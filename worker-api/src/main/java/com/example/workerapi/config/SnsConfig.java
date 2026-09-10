package com.example.workerapi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sqs.SqsClient;

@Configuration
public class SnsConfig {

    @Bean
    public SnsClient snsClient() {
        {
            return SnsClient.builder()
                    .region(Region.US_EAST_1)
                    .build();
        }
    }
}
