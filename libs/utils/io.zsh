#!/usr/bin/env zsh

function _log_message() {
    local level="$1"
    local message="$2"
    local stream="${3:-1}"

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local formatted_message="${timestamp}\t${level}\t${message}"

    echo "$formatted_message" >&$stream
}

function log_info() {
    _log_message "INFO" "$1" 1
}

function log_warning() {
    _log_message "WARN" "$1" 2
}

function log_error() {
    _log_message "ERROR" "$1" 2
    return 1
}