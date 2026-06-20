#!/usr/bin/env zsh

function run_orthofinder() {
    local input_taskname="$1"
    local input_taskdir="${TASKS}/${input_taskname}"
    if [ ! -d "$input_taskdir" ]; then
        log_error "input task directory not found: ${input_taskdir}"
        return 1
    fi

    local config_file="${input_taskdir}/config.zsh"
    if ! parse_config "$config_file"; then
        log_error "configuration failed"
        return 1
    fi

    if ! typeset -p SPECIES_LIST 2>/dev/null || [ ${#SPECIES_LIST} -eq 0 ]; then
        log_error "SPECIES_LIST array is undefined or empty"
        return 1
    fi

    : ${ORTHOFINDER_THREADS:=1}
    log_info "use ORTHOFINDER_THREADS=${ORTHOFINDER_THREADS}"

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P1-orthofinder-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local orthofinder_cmd="orthofinder -f ${input_taskdir} -t ${ORTHOFINDER_THREADS} -o ${output_taskdir}"
    log_info "running Orthofinder with command: ${orthofinder_cmd}"

    if ! eval "$orthofinder_cmd"; then
        log_error "Orthofinder execution failed"
        return 1
    fi

    log_info "Orthofinder completed successfully. Results are in: ${output_taskdir}"
}