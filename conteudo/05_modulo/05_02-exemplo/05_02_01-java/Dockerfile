# Use a valid Maven image with OpenJDK 17
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copy the source code and POM
COPY . .

# Build the application
RUN mvn clean package -DskipTests

# Use a minimal runtime JDK
FROM openjdk:17-jdk-slim

WORKDIR /app

# Copy the built JAR file
COPY --from=build /app/target/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
CMD ["java", "-jar", "app.jar"]
