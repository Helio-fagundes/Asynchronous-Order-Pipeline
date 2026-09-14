package com.example.workerapi.config;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/health")
public class healthCheck {

    @GetMapping
    public ResponseEntity<Void> status() {
        return ResponseEntity.ok().build();
    }
}
