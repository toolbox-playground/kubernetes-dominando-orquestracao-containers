package com.example.heavyapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Random;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@RestController
@RequestMapping("/test")
class HeavyTaskController {

    @GetMapping
    public String performHeavyTask() {
        int[][] matrix = new int[500][500];
        Random random = new Random();

        // Preenchendo a matriz com valores aleatórios
        for (int i = 0; i < 500; i++) {
            for (int j = 0; j < 500; j++) {
                matrix[i][j] = random.nextInt(1000);
            }
        }

        // Realizando cálculos pesados na matriz
        long sum = 0;
        for (int i = 0; i < 500; i++) {
            for (int j = 0; j < 500; j++) {
                sum += Math.sqrt(matrix[i][j]);
            }
        }

        return "Heavy computation done! Sum: " + sum;
    }
}
