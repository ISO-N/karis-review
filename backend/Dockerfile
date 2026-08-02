# syntax=docker/dockerfile:1

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY backend/pom.xml pom.xml
RUN mvn -B -q dependency:go-offline
COPY proto /proto
COPY backend/src src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app
RUN useradd --system --create-home --shell /usr/sbin/nologin appuser
COPY --from=build /workspace/target/karisreview-0.0.1-SNAPSHOT.jar /app/app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
