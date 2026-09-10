package com.example.produceapi.service.dto;

import java.math.BigDecimal;

public record ProducerRequestDto(String name, String email, String productName, BigDecimal price) {
}
