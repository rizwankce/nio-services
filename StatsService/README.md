# Statistics Service

## Getting Started

Clone the repository and run the following command to install the dependencies:

```bash
swift build
```

to run the server:

```bash
swift run StatsService # starts the server with localhost:2345
swift run StatsService --port 8080 # starts the server with the specified port
swift run StatsService --ip-address 127.0.0.1 # starts the server with the specified ip address
swift run StatsService --ip-address 127.0.0.1 --port 8080 # starts the server with the specified ip address and port
```

### Routes

- `/stats` - return JSON with the up-time of the service, and the average response time as well as min/max times for the entire life-time of the service
