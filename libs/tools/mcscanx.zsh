#!/usr/bin/env zsh

function add_gff_for_mcscanx() {
    local input_taskname="$1"
    local input_taskdir="${TASKS}/${input_taskname}"

    local input_taskname_1="$2"
    local input_taskdir_1="${TASKS}/${input_taskname_1}"

    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local output_taskname="P2-add_gff_for_mcscanx-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"

    local config_file="${input_taskdir}/config.zsh"
    if ! parse_config "$config_file"; then
        log_error "configuration failed"
        return 1
    fi

    if ! typeset -p SPECIES_LIST 2>/dev/null || [ ${#SPECIES_LIST} -eq 0 ]; then
        log_error "SPECIES_LIST array is undefined or empty"
        return 1
    fi

    local num_species=${#SPECIES_LIST}
    log_info "start all-to-all gff preparetion for ${num_species} species"

    local i j
    local total_jobs=0

    for ((i = 1; i <= num_species; i++)); do
        for ((j = i + 1; j <= num_species; j++)); do
            local species_i="${SPECIES_LIST[i]}"
            local species_j="${SPECIES_LIST[j]}"

            local pairname="${species_i}__${species_j}"
            local pairdir="${output_taskdir}/${pairname}"
            local output_file="${pairdir}/${pairname}.gff"
            local blast_file="${input_taskdir_1}/${pairname}/${pairname}.blast"

            mkdir -p "$pairdir"

            log_info "process pair: ${species_i} vs ${species_j}"

            local gff_i="${input_taskdir}/${species_i}.gff"
            local gff_j="${input_taskdir}/${species_j}.gff"

            if [ ! -f "$gff_i" ] || [ ! -f "$gff_j" ]; then
                log_warning "skip pair ${pairname}: one or both gff files not found"
                continue
            fi

            cat "$gff_i" "$gff_j" > "$output_file"
            log_info "concat gff file saved to: ${output_file}"

            if [ ! -f "$blast_file" ]; then
                log_error "blast file not found"
                rm -r "$pairdir" 2>/dev/null
                continue
            fi

            cp "$blast_file" "$pairdir"
            log_info "copy blast file to: ${pairdir}/${pairname}.blast"

            total_jobs=$((total_jobs + 1))
        done
    done

    log_info "all $total_jobs gff files added successfully"
    return 0
}