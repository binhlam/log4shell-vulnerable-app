# Stage 1: Build the application using JDK 17
FROM gradle:7.3.1-jdk17 AS builder
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle bootJar --no-daemon


# Stage 2: Create the final, hardened production image using JDK 8
FROM openjdk:8u181-jdk-alpine

# Fix for CKV_DOCKER_3: Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080
RUN mkdir /app
COPY --from=builder /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar

# Fix for CKV_DOCKER_2: Add a healthcheck for the Spring Boot Actuator
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1

CMD ["java", "-jar", "/app/spring-boot-application.jar"]
