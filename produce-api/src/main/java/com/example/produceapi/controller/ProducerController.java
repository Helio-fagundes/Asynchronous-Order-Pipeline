package com.example.produceapi.controller;

import com.example.produceapi.service.ProduceService;
import com.example.produceapi.service.dto.ProducerRequestDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/producers")
public class ProducerController {

    private final ProduceService service;


    public ProducerController(ProduceService service) {
        this.service = service;
    }

    @PostMapping()
    public ResponseEntity<String> produceMessage(@RequestBody ProducerRequestDto dto) {
        service.saveProducer(dto);
        return ResponseEntity.accepted().body("Mensagem enviada para a fila SQS com sucesso!");
    }
}
