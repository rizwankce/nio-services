# Ping Service

## Overview

The Ping Service is a server-side application written in Swift that allows clients to ping a server and receive a response. It is designed to test server availability and response time using the `swift-nio` framework.

## Features

- Simple ping endpoint for health checks and availability testing.
- Random response time between 20 ms to 5000 ms to simulate real-world network conditions.
- Statistics collection and export for performance analysis.

## Getting Started

### Prerequisites

- Swift 5.9 or later
- Xcode 15.2 or later (for macOS)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rizwankce`/nio-services.git
cd nio-services/PingService
```

2. Install the dependencies:

```bash
swift build
```

### Running the Server

To start the server, run the following command:

```bash
swift run PingService
```

By default, the server will start on `localhost:2345`. You can specify a different port or IP address using the following options:

```bash
swift run PingService --port 2345 # starts the server with the specified port
swift run PingService --ip-address 127.0.0.1 # starts the server with the specified IP address
swift run PingService --ip-address 127.0.0.1 --port 2345 # starts the server with the specified IP address and port
```

### Usage

```bash
ping-service [--verbose] [--host <host>] [--port <port>] <window-size> <file-path>

ARGUMENTS:
  <window-size>           Size of window to get average, min and max response times
  <file-path>             File Path for saving the response times

OPTIONS:
  -v, --verbose           Print status updates while server running.
  -h, --host <host>       Host to bind
  -p, --port <port>       Port number to bind
  -h, --help              Show help information.
```

### API Routes

- `GET /ping`: Returns a simple JSON response with the message "ok" with a status code of 200. The response time will vary for each request, ranging from 20 ms to 5000 ms.

### Example Requests

Here are some example requests you can make to the server:

```bash
curl http://localhost:2345/ping
```

### Testing

To run the tests, execute the following command:

```bash
swift test
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](../LICENSE) file for details.
