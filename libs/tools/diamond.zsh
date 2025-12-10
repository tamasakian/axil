#!/usr/bin/env zsh

function blastp_for_mcscanx() {
    local input_taskname="$1"
    local input_taskdir="${TASKS}/${input_taskname}"

    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local output_taskname="P1-blastp_for_mcscanx-${timestamp}"
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

    if [ -z "$DIAMOND_THREADS" ]; then
        local default_threads=1
        DIAMOND_THREADS="$default_threads"
        log_info "use DIAMOND_THREADS default: ${DIAMOND_THREADS}"
    fi

    local num_species=${#SPECIES_LIST}
    log_info "start all-to-all blastp preparetion for ${num_species} species"

    local i j
    local total_jobs=0

    for ((i = 1; i <= num_species; i++)); do
        for ((j = i + 1; j <= num_species; j++)); do
            local species_i="${SPECIES_LIST[i]}"
            local species_j="${SPECIES_LIST[j]}"

            local pairname="${species_i}__${species_j}"
            local pairdir="${output_taskdir}/${pairname}"
            local output_file="${pairdir}/${pairname}.blast"

            mkdir -p "$pairdir"

            log_info "process pair: ${species_i} vs ${species_j}"

            local fasta_i="${input_taskdir}/${species_i}.fasta"
            local fasta_j="${input_taskdir}/${species_j}.fasta"

            if [ ! -f "$fasta_i" ] || [ ! -f "$fasta_j" ]; then
                log_warning "skip pair ${pairname}: one or both fasta files not found"
                continue
            fi

            local db_file="${pairdir}/${species_j}.dmnd"
            log_info "build diamond db for ${species_j}"

            if ! diamond makedb --in "$fasta_j" -d "$db_file"; then
                log_error "diamond db creation failed for ${species_j}"
                return 1
            fi

            log_info "run diamond blastp: ${species_i} vs ${species_j}"

            if ! diamond blastp \
                -q "$fasta_i" \
                -d "$db_file" \
                -o "$output_file" \
                --threads "$DIAMOND_THREADS" \
                --outfmt 6; then

                log_error "diamond blastp failed for ${pairname}"
                return 1
            fi

            rm -f "$db_file"

            log_info "blast output saved to: ${output_file}"
            total_jobs=$((total_jobs + 1))
        done
    done

    log_info "all $total_jobs blast runs completed successfully"
    return 0
}