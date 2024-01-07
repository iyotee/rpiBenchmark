#!/bin/bash
# rpi-benchmark.sh - Raspberry Pi Benchmark Script

# Function to display an error message and exit
function display_error() {
    echo -e "\e[91mError: $1\e[0m"
    exit 1
}

# Function to display hardware information
function display_hardware_info() {
    echo -e "\n\e[96mHardware Information:\e[0m"
    echo -e "---------------------"
    echo -e "\e[94mCPU Model:\e[0m $(lscpu | awk -F': ' '/Model name/ {print $2}')"
    echo -e "\e[94mArchitecture:\e[0m $(lscpu | awk -F': ' '/Architecture/ {print $2}')"
    echo -e "\e[94mCores:\e[0m $(nproc)"
    echo -e "\e[94mTotal Memory:\e[0m $(free -h | awk '/^Mem:/ {print $2}')"
    echo -e "\e[94mTotal Swap:\e[0m $(free -h | awk '/^Swap:/ {print $2}')"
    echo -e "\e[94mKernel Version:\e[0m $(uname -r)"
    echo -e "\e[94mDisk Size:\e[0m $(df -h --total | awk '/total/ {print $2}')"
    echo -e "\e[94mDisk Used:\e[0m $(df -h --total | awk '/total/ {print $3}')"
    echo -e "\e[94mDisk Available:\e[0m $(df -h --total | awk '/total/ {print $4}')"

    # Additional hardware information
    echo -e "\n\e[94mTemperature:\e[0m $(vcgencmd measure_temp)"
    echo -e "\e[94mCPU Frequency:\e[0m $(vcgencmd get_config int | grep arm_freq)"
    echo -e "\e[94mCore Frequency:\e[0m $(vcgencmd get_config int | grep core_freq)"
    echo -e "\e[94mSDRAM Frequency:\e[0m $(vcgencmd get_config int | grep sdram_freq)"
    echo -e "\e[94mGPU Frequency:\e[0m $(vcgencmd get_config int | grep gpu_freq)"
    echo -e "\e[94mSD Card Clock:\e[0m $(grep "actual clock" /sys/kernel/debug/mmc0/ios 2>/dev/null | awk '{printf("%.3f MHz", $3/1000000)}')"
    echo -e "---------------------"
}

# Function to display network information
function display_network_info() {
    echo -e "\n\e[96mNetwork Information:\e[0m"
    echo -e "---------------------"
    echo -e "\e[94mHostname:\e[0m $(hostname)"
    echo -e "\e[94mInternal IP Address:\e[0m $(hostname -I | awk '{print $1}')"
    echo -e "\e[94mExternal IP Address:\e[0m $(curl -s ifconfig.me)"
    echo -e "\e[94mSubnet Mask:\e[0m $(ip route | awk '/proto/ {print $3}')"
    echo -e "\e[94mGateway:\e[0m $(ip route | awk '/default/ {print $3}')"
    echo -e "\e[94mDNS Servers:\e[0m $(cat /etc/resolv.conf | awk '/nameserver/ {print $2}' | tr '\n' ' ')"
    echo -e "\e[94mMac Address:\e[0m $(ip link | awk '/ether/ {print $2}')"
    echo -e "---------------------"
}

# Display hardware information
display_hardware_info

# Display network information
display_network_info

# Check for administrator privileges
if [[ $EUID -ne 0 ]]; then
    display_error "This script must be run as an administrator (root)."
fi

# Function to install required packages
function install_packages() {
    local packages=("speedtest-cli" "hdparm" "sysbench")

    for package in "${packages[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            echo "Installing $package..."
            apt-get install -y "$package" || display_error "Failed to install $package."
        fi
    done
}

# Install required packages
install_packages

# Function to run benchmark
function run_benchmark() {
    local benchmark_type=$1
    echo -e "\n\e[96m${benchmark_type^} Benchmark...\e[0m"
    local results=$(sysbench "$benchmark_type" --threads=4 run)
    local min=$(grep 'min:' <<< "$results" | awk '{print $2}')
    local avg=$(grep 'avg:' <<< "$results" | awk '{print $2}')
    local max=$(grep 'max:' <<< "$results" | awk '{print $2}')

    echo -e "\e[93m$(vcgencmd measure_temp)\e[0m"

    printf "+---------------------+----------------------+\n"
    printf "| \e[96mMetric\e[0m              | \e[96mScore\e[0m                |\n"
    printf "+---------------------+----------------------+\n"
    printf "| Minimum Time        | \e[92m%-20s\e[0m |\n" "${min} seconds"
    printf "| Average Time        | \e[92m%-20s\e[0m |\n" "${avg} seconds"
    printf "| Maximum Time        | \e[92m%-20s\e[0m |\n" "${max} seconds"
    printf "+---------------------+----------------------+\n"
}

# Function for Disk benchmark
function benchmark_disk() {
    echo -e "\n\e[96mDisk Benchmark...\e[0m"

    # Running HDPARM test
    echo -e "Running HDPARM test...\e[94m"
    local disk_read_speed=$(hdparm -t /dev/mmcblk0 | grep -oP '\d+\.\d+' | tail -n 1)

    # Running DD WRITE test
    echo -e "Running DD WRITE test...\e[94m"
    local disk_write_speed=$(rm -f ~/test.tmp && sync && dd if=/dev/zero of=~/test.tmp bs=1M count=512 conv=fsync 2>&1 | grep -oP '\d+\.\d+' | tail -n 1)

    # Running DD READ test
    echo -e "Running DD READ test...\e[94m"
    local disk_read_dd_speed=$(echo -e 3 > /proc/sys/vm/drop_caches && sync && dd if=~/test.tmp of=/dev/null bs=1M 2>&1 | grep -oP '\d+\.\d+' | tail -n 1)

    # Display temperature
    echo -e "\e[93m$(vcgencmd measure_temp)\e[0m"

    # Display results
    printf "+---------------------------+--------------------------------+\n"
    printf "| \e[96mMetric\e[0m                    | \e[96mScore\e[0m                          |\n"
    printf "+---------------------------+--------------------------------+\n"
    printf "| Disk Score (Write Speed)	| \e[92m%-26s\e[0m |\n" "${disk_write_speed} MB/s"
    printf "| Disk Score (Read Speed)	| \e[92m%-26s\e[0m |\n" "${disk_read_dd_speed} MB/s"
    printf "+---------------------------+--------------------------------+\n"
}

# Function for Network benchmark
function benchmark_network() {
    echo -e "\n\e[96mNetwork Benchmark...\e[0m"
    local speedtest_results=$(speedtest-cli --simple)
    local network_download=$(grep 'Download' <<< "$speedtest_results" | awk '{print $2}')  # in Mbps
    local network_upload=$(grep 'Upload' <<< "$speedtest_results" | awk '{print $2}')      # in Mbps
    local network_ping=$(grep 'Ping' <<< "$speedtest_results" | awk '{print $2}')          # in ms

    echo -e "\e[93m$(vcgencmd measure_temp)\e[0m"

    printf "+----------------------+-------------------+\n"
    printf "| \e[96mMetric\e[0m		| \e[96mScore\e[0m		|\n"
    printf "+----------------------+-------------------+\n"
    printf "| Download Speed      | \e[92m%-18s\e[0m |\n" "${network_download} Mbps"
    printf "| Upload Speed        | \e[92m%-18s\e[0m |\n" "${network_upload} Mbps"
    printf "| Ping (Average Time) | \e[92m%-18s\e[0m |\n" "${network_ping} ms"
    printf "+----------------------+-------------------+\n"
}

# Function for the main menu
function main_menu() {
    echo -e "\n\e[96mBenchmark Menu:\e[0m"
    echo "1. CPU Benchmark"
    echo "2. Threads Benchmark"
    echo "3. Memory Benchmark"
    echo "4. Disk Benchmark"
    echo "5. Network Benchmark"
    echo "6. Run All Benchmarks"
    echo "7. Exit"
    echo -n "Enter your choice (1-7): "
    read -r choice

    case $choice in
        1) run_benchmark "cpu" ;;
        2) run_benchmark "threads" ;;
        3) run_benchmark "memory" ;;
        4) benchmark_disk ;;
        5) benchmark_network ;;
        6) run_all_benchmarks ;;
        7) echo -e "\nExiting...\e[0m" ; exit 0 ;;
        *) echo -e "\e[91mInvalid choice. Please enter a number from 1 to 7.\e[0m" ;;
    esac
}

# Function to run all benchmarks
function run_all_benchmarks() {
    echo -e "\n\e[96mRunning All Benchmarks...\e[0m"

    run_benchmark "cpu"
    run_benchmark "threads"
    run_benchmark "memory"
    benchmark_disk
    benchmark_network
}

# Main function
function main() {
    while true; do
        main_menu
    done
}

# Call the main function
main
