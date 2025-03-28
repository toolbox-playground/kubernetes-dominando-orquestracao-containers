package com.example.memoryconsume;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
public class MemoryConsumeApplication {

    public static void main(String[] args) {
        SpringApplication.run(MemoryConsumeApplication.class, args);
    }
}

@RestController
class MemoryConsumeController {

    // Simulating memory consumption
    public List<Object> consumeMemory() {
        List<Object> largeList = new ArrayList<>();
        // Keep adding objects to the list to consume memory
        for (int i = 0; i < 1000000; i++) {  // Adjust the number as needed
            largeList.add(new MemoryObject("This is a large object to consume memory"));
        }
        return largeList;
    }

    @GetMapping("/home")
    public String home() {
        // Consume memory before sending the response
        consumeMemory();
        
        // Send a response to the client
        return "{\"message\": \"Test!\"}";
    }
}

class MemoryObject {
    private String data;

    public MemoryObject(String data) {
        this.data = data;
    }

    public String getData() {
        return data;
    }

    public void setData(String data) {
        this.data = data;
    }
}
