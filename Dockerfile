#Using lightweight openjdk 17-alpine
FROM nexus.thanhnc85.lab:8085/openjdk:17-alpine

WORKDIR /app

COPY target/*.jar springapp.jar

RUN mkdir -p log

ENTRYPOINT ["java", "-jar"]

CMD ["-DLOG_DIR=log", "springapp.jar"]