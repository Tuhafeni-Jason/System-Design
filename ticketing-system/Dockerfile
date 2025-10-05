# Use Ballerina Swan Lake latest (matches your setup)
FROM ballerina/ballerina:latest

# Set working directory
WORKDIR /app

# Copy Ballerina project files (context is the service dir)
COPY . /app

# Build JAR (bal build auto-resolves deps from Ballerina.toml and skips test execution by default)
RUN bal build

# Expose HTTP port
EXPOSE 8080

# Run the generated JAR (dynamically finds the service JAR, e.g., passenger.jar)
CMD ["sh", "-c", "java -jar target/bin/*.jar"]