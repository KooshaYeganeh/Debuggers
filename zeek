#!/bin/bash

# Variables
CONFIG_DIR="/usr/local/zeek/etc"
LOCAL_ZEEK_SCRIPT="$CONFIG_DIR/zeekctl.cfg"
NODE_CFG="$CONFIG_DIR/node.cfg"
NETWORK_CFG="$CONFIG_DIR/networks.cfg"
LOG_FILE="/usr/local/zeek/logs/check_zeek_config.log"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print success message
function print_success {
    echo -e "${GREEN}$1${NC}"
}

# Function to print error message
function print_error {
    echo -e "${RED}$1${NC}"
}

# Function to log recommendations
function log_recommendation {
    echo "$1" >> $LOG_FILE
}

# Function to check a configuration setting
function check_setting {
    local file=$1
    local setting=$2
    local recommendation=$3

    if grep -q "$setting" "$file"; then
        print_success "Setting $setting found in $file"
    else
        print_error "Setting $setting not found in $file"
        log_recommendation "Recommendation: Add $setting to $file. $recommendation"
    fi
}

# Function to recommend best practices
function recommend_best_practices {
    echo "Checking Zeek configuration for best practices..."

    # Example checks (add more as needed)
    check_setting $LOCAL_ZEEK_SCRIPT "MailTo" "Set a valid email address to receive critical alerts."
    check_setting $NODE_CFG "type=manager" "Ensure there is a manager node defined."
    check_setting $NODE_CFG "type=logger" "Ensure there is a logger node defined."
    check_setting $NODE_CFG "type=worker" "Ensure there are worker nodes defined."
    check_setting $NETWORK_CFG "172.16.0.0/12" "Define the internal network ranges to monitor."
    check_setting $NETWORK_CFG "10.0.0.0/8" "Define the internal network ranges to monitor."
    check_setting $NETWORK_CFG "192.168.0.0/16" "Define the internal network ranges to monitor."

    # Check for file extraction security
    if grep -q "extract-all-files" $LOCAL_ZEEK_SCRIPT; then
        print_success "File extraction is enabled."
    else
        print_error "File extraction is not enabled."
        log_recommendation "Recommendation: Enable file extraction by adding @load base/frameworks/files/extract-all-files to $LOCAL_ZEEK_SCRIPT."
    fi

    # Check for logging of sensitive events
    if grep -q "Notice::" $LOCAL_ZEEK_SCRIPT; then
        print_success "Sensitive event logging is configured."
    else
        print_error "Sensitive event logging is not configured."
        log_recommendation "Recommendation: Configure sensitive event logging by adding Notice:: policies to $LOCAL_ZEEK_SCRIPT."
    fi
}

# Clear previous log file
> $LOG_FILE

# Check if configuration files exist
if [ ! -f "$LOCAL_ZEEK_SCRIPT" ]; then
    print_error "Zeek configuration file $LOCAL_ZEEK_SCRIPT does not exist."
    exit 1
fi

if [ ! -f "$NODE_CFG" ]; then
    print_error "Zeek node configuration file $NODE_CFG does not exist."
    exit 1
fi

if [ ! -f "$NETWORK_CFG" ]; then
    print_error "Zeek network configuration file $NETWORK_CFG does not exist."
    exit 1
fi

# Run the configuration checks
recommend_best_practices

# Print the recommendations log
print_success "Zeek configuration check completed. Recommendations (if any):"
cat $LOG_FILE

