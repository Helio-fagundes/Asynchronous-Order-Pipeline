package com.example.produceapi.service;

import com.example.produceapi.entity.Pedido;
import com.example.produceapi.service.dto.ProducerRequestDto;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.math.BigDecimal;

@Service
public class ProduceService {

    private final DynamoDbTable<Pedido> producerTable;
    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;

    @Value("${sqs_url}")
    private String queueUrl;

    public ProduceService(
            DynamoDbEnhancedClient enhancedClient,
            SqsClient sqsClient,
            @Value("${dynamo_table_name}") String tableName
    ) {
        this.producerTable = enhancedClient.table(tableName, TableSchema.fromBean(Pedido.class));
        this.sqsClient = sqsClient;
        this.objectMapper = new ObjectMapper();
    }

    public void saveProducer(ProducerRequestDto requestDto) {
        validation(requestDto);
        Pedido producer = new Pedido();
        producer.setId(java.util.UUID.randomUUID());
        producer.setName(requestDto.name());
        producer.setEmail(requestDto.email());
        producer.setProductName(requestDto.productName());
        producer.setPrice(requestDto.price());
        producer.setStatus("PENDING");

        producerTable.putItem(producer);

        try {
            String jsonMessage = objectMapper.writeValueAsString(producer);

            SendMessageRequest sendMsgRequest = SendMessageRequest.builder()
                    .queueUrl(this.queueUrl)
                    .messageBody(jsonMessage)
                    .build();

            sqsClient.sendMessage(sendMsgRequest);

        } catch (Exception e) {
            throw new RuntimeException("Falha ao enviar mensagem para o SQS", e);
        }
    }

    private void validation(ProducerRequestDto requestDto) {
        if (requestDto.name() == null || requestDto.name().isEmpty()) {
            throw new IllegalArgumentException("Name is required");
        }
        if (requestDto.email() == null || requestDto.email().isEmpty()) {
            throw new IllegalArgumentException("Email is required");
        }
        if (requestDto.productName() == null || requestDto.productName().isEmpty()) {
            throw new IllegalArgumentException("Product name is required");
        }
        if (requestDto.price() == null || requestDto.price().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Price must be greater than zero");
        }
    }
}
