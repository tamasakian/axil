#!/usr/bin/env zsh

function concat_gff_for_mcscanx() {
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

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P2-concat_gff_for_mcscanx-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local i j
    local total_times=0
    local num_species=${#SPECIES_LIST}
    for ((i = 1; i <= num_species; i++)); do
        for ((j = i + 1; j <= num_species; j++)); do
            local species_i="${SPECIES_LIST[i]}"
            local species_j="${SPECIES_LIST[j]}"
            local pairname="${species_i}__${species_j}"

            local gff_i="${input_taskdir}/${species_i}.gff"
            local gff_j="${input_taskdir}/${species_j}.gff"
            if [ ! -f "$gff_i" ] || [ ! -f "$gff_j" ]; then
                log_warning "skip pair ${pairname}: one or both gff files not found"
                continue
            fi

            local pairdir="${output_taskdir}/${pairname}"
            mkdir -p "$pairdir"

            local output_file="${pairdir}/${pairname}.gff"
            if ! cat "$gff_i" "$gff_j" > "$output_file"; then
                log_error "concatination failed"
                return 1
            fi

            log_info "output gff file saved to: ${output_file}"
            total_times=$((total_times + 1))
        done
    done

    log_info "all ${total_times} concatinations completed successfully"
    return 0
}

function run_mcscanx() {
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

    local input_taskname_1="$2"
    local input_taskdir_1="${TASKS}/${input_taskname_1}"
    if [ ! -d "$input_taskdir_1" ]; then
        log_error "input task directory not found: ${input_taskdir_1}"
        return 1
    fi

    local input_taskname_2="$3"
    local input_taskdir_2="${TASKS}/${input_taskname_2}"
    if [ ! -d "$input_taskdir_2" ]; then
        log_error "input task directory not found: ${input_taskdir_2}"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P3-run_mcscanx-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local i j
    local total_times=0
    local num_species=${#SPECIES_LIST}
    for ((i = 1; i <= num_species; i++)); do
        for ((j = i + 1; j <= num_species; j++)); do
            local species_i="${SPECIES_LIST[i]}"
            local species_j="${SPECIES_LIST[j]}"
            local pairname="${species_i}__${species_j}"

            local input_blast="${input_taskdir_1}/${pairname}/${pairname}.blast"
            local input_gff="${input_taskdir_2}/${pairname}/${pairname}.gff"
            if [ ! -f "$input_blast" ] || [ ! -f "$input_gff" ]; then
                log_warning "skip pair: input blast or gff file missing"
                continue
            fi

            local pairdir="${output_taskdir}/${pairname}"
            mkdir -p "$pairdir"

            cp "$input_blast" "$pairdir/"
            cp "$input_gff" "$pairdir/"
            if ! ( cd "$pairdir" && MCScanX "$pairname" ); then
                log_error "mcscanx execution failed for ${pairname}"
                rm -r "$pairdir" 2>/dev/null
                continue
            fi

            total_times=$((total_times + 1))
        done
    done

    log_info "all ${total_times} mcscanx runs completed successfully"
    return 0
}

function run_classifier() {
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

    local input_taskname_1="$2"
    local input_taskdir_1="${TASKS}/${input_taskname_1}"
    if [ ! -d "$input_taskdir_1" ]; then
        log_error "input task directory not found: ${input_taskdir_1}"
        return 1
    fi

    local input_taskname_2="$3"
    local input_taskdir_2="${TASKS}/${input_taskname_2}"
    if [ ! -d "$input_taskdir_2" ]; then
        log_error "input task directory not found: ${input_taskdir_2}"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P4-run_classifier-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local i j
    local total_times=0
    local num_species=${#SPECIES_LIST}
    for ((i = 1; i <= num_species; i++)); do
        for ((j = i + 1; j <= num_species; j++)); do
            local species_i="${SPECIES_LIST[i]}"
            local species_j="${SPECIES_LIST[j]}"
            local pairname="${species_i}__${species_j}"

            local input_blast="${input_taskdir_1}/${pairname}/${pairname}.blast"
            local input_gff="${input_taskdir_2}/${pairname}/${pairname}.gff"
            if [ ! -f "$input_blast" ] || [ ! -f "$input_gff" ]; then
                log_warning "skip pair: input blast or gff file missing"
                continue
            fi

            local pairdir="${output_taskdir}/${pairname}"
            mkdir -p "$pairdir"

            cp "$input_blast" "$pairdir/"
            cp "$input_gff" "$pairdir/"
            if ! ( cd "$pairdir" && duplicate_gene_classifier "$pairname" ); then
                log_error "duplicate_gene_classifier execution failed for ${pairname}"
                rm -r "$pairdir" 2>/dev/null
                continue
            fi

            total_times=$((total_times + 1))
        done
    done

    log_info "all ${total_times} duplicate_gene_classifier runs completed successfully"
    return 0
}