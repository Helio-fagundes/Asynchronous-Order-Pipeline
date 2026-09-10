package com.example.workerapi.service;

import com.example.workerapi.entity.Pedido;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.awspring.cloud.sqs.annotation.SqsListener;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

import java.util.HashMap;
import java.util.Map;

@Service
public class WorkerService {

    private final DynamoDbTable<Pedido> workerTable;
    private final SnsClient snsClient;
    private final ObjectMapper objectMapper;

    @Value("${topic-arn}")
    private String topicArn;

    public WorkerService(DynamoDbEnhancedClient enhancedClient, SnsClient snsClient) {
        this.workerTable = enhancedClient.table("tabela-requisicoes-validadas", TableSchema.fromBean(Pedido.class));
        this.snsClient = snsClient;
        this.objectMapper = new ObjectMapper();
    }

    @SqsListener("${sqs_url}")
    public void receiveMessage(Pedido pedidoRecebido) {
        try {
            pedidoRecebido.setStatus("ACCEPTED");
            workerTable.updateItem(pedidoRecebido);

            Map<String, String> snsPayload = new HashMap<>();
            snsPayload.put("id_pedido", String.valueOf(pedidoRecebido.getId()));
            snsPayload.put("email_cliente", pedidoRecebido.getEmail());
            snsPayload.put("nome_cliente", pedidoRecebido.getName());
            snsPayload.put("status", pedidoRecebido.getStatus());

            String jsonSns = objectMapper.writeValueAsString(snsPayload);

            PublishRequest publishRequest = PublishRequest.builder()
                    .topicArn(this.topicArn)
                    .message(jsonSns)
                    .build();

            snsClient.publish(publishRequest);
            System.out.println("Funcionou o sns foi enviado");

        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
