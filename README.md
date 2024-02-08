# Swift NoIO Services

This repository contains a collection of server-side applications written in Swift using the `swift-nio` framework. The services are designed to demonstrate various functionalities such as pinging, statistics collection, and search capabilities.

## Services

- [Ping Service](./PingService/README.md): A service that allows clients to ping a server and receive a response, useful for testing server availability and response time.
- [Statistics Service](./StatsService/README.md): A service that provides statistics related to server performance, including uptime and response times.
- [Search Service](./SearchService/README.md): A service that allows clients to search for data using a search query, providing efficient search functionality for finding facilities by name and retrieving facility locations.

## Getting Started

### Prerequisites

- Swift 5.9 or later
- Xcode 15.2 or later (for macOS)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/rizwankce/nio-services.git
```

2. Navigate to the service folder you want to run:

```bash
cd nio-services/PingService # or StatsService or SearchService

```

3. Install the dependencies:

```bash
swift build
```

4. Run the service:

```bash
swift run PingService # or StatsService or SearchService
```

### Running the Services

Each service can be run independently by navigating to its directory and following the instructions provided in its `README.md` file.

### Testing

To run the tests for each service, navigate to the service's directory and execute the following command:

```bash
swift test
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](./LICENSE) file for details.
