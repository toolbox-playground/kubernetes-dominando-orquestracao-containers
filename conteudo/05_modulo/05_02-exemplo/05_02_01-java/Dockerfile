# Usa uma imagem oficial do OpenJDK
FROM openjdk:17
WORKDIR /app

# Copia o código para dentro do contêiner
COPY . .

RUN mvn clean package

# Comando para rodar a aplicação
CMD ["java", "-jar", "app.jar"]

# Expõe a porta do serviço
EXPOSE 8080
