# Raspberry Pi Performance Benchmark and Monitoring Script

## Overview

This Bash script is designed for benchmarking a Raspberry Pi's performance and monitoring various hardware and network metrics. It includes functionalities for CPU, memory, disk, and network benchmarks, as well as a stress test with real-time CPU temperature monitoring.

## Features

- **Hardware Information:** Displays details about the Raspberry Pi's hardware, including CPU model, architecture, core count, memory, disk size, and more.

- **Network Information:** Provides information about the network configuration, including hostname, internal and external IP addresses, subnet mask, gateway, DNS servers, and MAC address.

- **Benchmarks:**
  - **CPU Benchmark:** Measures the CPU performance using sysbench.
  - **Threads Benchmark:** Evaluates the system's threading capabilities.
  - **Memory Benchmark:** Tests memory operations using sysbench.
  - **Disk Benchmark:** Assesses disk performance through DD write and read tests.
  - **Network Benchmark:** Measures download speed, upload speed, and ping using speedtest-cli.

- **Stress Test:** Conducts a stress test on the CPU using stress-ng with real-time temperature monitoring.

## Usage

1. Clone the repository:

    ```bash
    git clone [https://github.com/iyotee/rpi-benchmark.git](https://github.com/iyotee/rpiBenchmark.git)
    ```

2. Navigate to the script's directory:

    ```bash
    cd rpi-benchmark
    ```

3. Make the script executable:

    ```bash
    chmod +x rpi-benchmark.sh
    ```

4. Run the script:

    ```bash
    ./rpi-benchmark.sh
    ```

## Dependencies

- `sysbench`
- `hdparm`
- `speedtest-cli`
- `stress-ng`

The script will check for the presence of each dependency and automatically install any missing packages.

## License

This script is licensed under the [MIT License](LICENSE).

Feel free to contribute and provide feedback!

