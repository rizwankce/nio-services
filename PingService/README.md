# Ping Service

## Getting Started

Clone the repository and run the following command to install the dependencies:

```bash
swift build
```

to run the server:

```bash
swift run PingService # starts the server with localhost:2345
swift run PingService --port 8080 # starts the server with the specified port
swift run PingService --ip-address 127.0.0.1 # starts the server with the specified ip address
swift run PingService --ip-address 127.0.0.1 --port 8080 # starts the server with the specified ip address and port
```

### Routes

- `GET /ping`: Returns a simple JSON response with the message "ok" with a status code of 200.
  response time will be vary for each request in random between 20 ms to 5000 ms
