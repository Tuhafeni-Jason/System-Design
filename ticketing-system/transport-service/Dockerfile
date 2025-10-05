FROM ballerina/ballerina:swan-lake

WORKDIR /app

COPY . .


RUN bal build --skip-tests


EXPOSE 8080


CMD ["java", "-jar", "target/bin/passenger.jar"]