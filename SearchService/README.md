# Search Service

## Overview

The Search Service is a server-side application written in Swift that provides a RESTful API for searching and retrieving data related to observing facilities. It uses the `swift-nio` framework to handle HTTP requests and responses efficiently.

## Features

- Efficient search functionality for finding facilities by name.
- Retrieval of facility locations based on UUIDs.
- Automatic data updates and maintenance.

## Getting Started

### Prerequisites

- Swift 5.9 or later
- Xcode 15.2 or later (for macOS)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rizwankce/nio-services.git cd nio-services/SearchService
```

2. Install the dependencies:

```bash
swift build
```

### Running the Server

To start the server, run the following command:

```bash
swift run SearchService
```

By default, the server will start on `localhost:2345`. You can specify a different port or IP address using the following options:

```bash
swift run SearchService --port 2345 # starts the server with the specified port
swift run SearchService --ip-address 127.0.0.1 # starts the server with the specified IP address
swift run SearchService --ip-address 127.0.0.1 --port 2345 # starts the server with the specified IP address and port
```

### Usage

```bash
search-service [--verbose] [--host <host>] [--port <port>] [--url <url>] --polis-remote-data-file-path <polis-remote-data-file-path> [--polis-static-data-file-path <polis-static-data-file-path>]

OPTIONS:
  -v, --verbose           Print status updates while server running.
  -h, --host <host>       Host to bind
  -p, --port <port>       Port number to bind
  -u, --url <url>         URL to download polis data from
  --polis-remote-data-file-path <polis-remote-data-file-path>
                          File Path to store the copied polis data
  --polis-static-data-file-path <polis-static-data-file-path>
                          **For testing purpose only.** Will use the path as source for polis resource
  -h, --help              Show help information.
```

### API Routes

All routes return JSON as a response.

- `/api/updatedDate` - Returns the last update date of the data set.
- `/api/numberOfObservingFacilities` - Returns the number of facilities in the current data set.
- `/api/search?name=xxx` - Returns the UUIDs of all facilities with a name containing the search criteria.
- `/api/location?uuid=UUID` - Returns the longitude and latitude (as Double values) of a facility with a given UUID.

### Example Requests

Here are some example requests you can make to the server:

```bash
curl http://localhost:2345/api/updatedDate
curl http://localhost:2345/api/numberOfObservingFacilities
curl http://localhost:2345/api/search?name=Observatory
curl http://localhost:2345/api/location?uuid=0A06F1F9-4C8C-480A-9CF1-A04B212DBF7F
```

### Testing

To run the tests, execute the following command:

```bash
swift test
```

## License

This project is licensed under the Apache License - see the [LICENSE.md](../LICENSE) file for details.
