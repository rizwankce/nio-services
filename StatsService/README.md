# Statistics Service

## Overview

The Statistics Service is a server-side application written in Swift that provides a RESTful API for monitoring server performance. It uses the `swift-nio` framework to handle HTTP requests and responses efficiently.

## Features

- Monitoring of server uptime and response times.
- Generation of statistics for the entire life-time of the service.
- Export of statistics to JSON format for further analysis.

## Getting Started

### Prerequisites

- Swift 5.9 or later
- Xcode 15.2 or later (for macOS)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rizwankce/nio-services.git
cd nio-services/StatsService
```

2. Install the dependencies:

```bash
swift build
```

### Running the Server

To start the server, run the following command:

```bash
swift run StatsService
```

By default, the server will start on `localhost:2345`. You can specify a different port or IP address using the following options:

```bash
swift run StatsService --port 2346 # starts the server with the specified port
swift run StatsService --ip-address 127.0.0.1 # starts the server with the specified IP address
swift run StatsService --ip-address 127.0.0.1 --port 2346 # starts the server with the specified IP address and port
```

### Usage

```bash
stats-service [--verbose] [--ping-host <ping-host>] [--ping-port <ping-port>] [--host <host>] [--port <port>] <delay>

ARGUMENTS:
  <delay>                 Delay to access the ping server (in milli seconds)

OPTIONS:
  -v, --verbose           Print status updates while server running.
  --ping-host <ping-host> Ping Server Host to connect
  --ping-port <ping-port> Ping Server Port number to connect
  -h, --host <host>       Host to bind
  -p, --port <port>       Port number to bind
  -h, --help              Show help information.
```

### API Routes

All routes return JSON as a response.

- `/stats` - Returns JSON with the up-time of the service, and the average response time as well as min/max times for the entire life-time of the service.

### Example Requests

Here are some example requests you can make to the server:

```bash
curl http://localhost:2346/stats
```

### Testing

To run the tests, execute the following command:

```bash
swift test
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](../LICENSE) file for details.
