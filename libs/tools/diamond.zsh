#!/usr/bin/env zsh

function blastp_for_mcscanx() {
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

    if [ -z "$DIAMOND_THREADS" ]; then
        local default_threads=1
        DIAMOND_THREADS="$default_threads"
        log_info "use default DIAMOND_THREADS: ${DIAMOND_THREADS}"
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P1-blastp_for_mcscanx-${timestamp}"
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

            local fasta_i="${input_taskdir}/${species_i}.fasta"
            local fasta_j="${input_taskdir}/${species_j}.fasta"
            if [ ! -f "$fasta_i" ] || [ ! -f "$fasta_j" ]; then
                log_warning "skip pair ${pairname}: one or both fasta files not found"
                continue
            fi

            local pairdir="${output_taskdir}/${pairname}"
            mkdir -p "$pairdir"

            local db_file="${pairdir}/${species_j}.dmnd"
            if ! diamond makedb --in "$fasta_j" -d "$db_file"; then
                log_error "diamond makedb failed for ${species_j}"
                return 1
            fi

            local output_file="${pairdir}/${pairname}.blast"
            if ! diamond blastp \
                -q "$fasta_i" \
                -d "$db_file" \
                -o "$output_file" \
                --threads "$DIAMOND_THREADS" \
                --outfmt 6; then
                log_error "diamond blastp failed for ${pairname}"
                return 1
            fi

            log_info "blast output saved to: ${output_file}"
            total_times=$((total_times + 1))
        done
    done

    log_info "all ${total_times} blast runs completed successfully"
    return 0
}

function run_blastp() {
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

    if [ -z "$REF_FASTA" ] || [ -z "$QRY_FASTA" ]; then
        log_error "REF_FASTA or QRY_FASTA are missing"
        return 1
    fi

    : ${DIAMOND_THREADS:=1}
    log_info "use DIAMOND_THREADS=${DIAMOND_THREADS}"

    : ${BLAST_EVALUE:="1e-5"}
    log_info "Us3 BLAST_EVALUE=${BLAST_EVALUE}"

    local ref_fasta="${input_taskdir}/${REF_FASTA}"
    local qry_fasta="${input_taskdir}/${QRY_FASTA}"
    if [ ! -f "$ref_fasta" ] || [ ! -f "$qry_fasta" ]; then
        log_error "one or both input fasta files not found"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P1-run_blastp-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local db_file="${output_taskdir}/ref.dmnd"
    if ! diamond makedb --in "$ref_fasta" -d "$db_file"; then
        log_error "$context" "Diamond DB creation failed."
        return 1
    fi

    local output_file="${output_taskdir}/blastp.results"
    if ! diamond blastp \
        -q "$qry_fasta" \
        -d "$db_file" \
        -o "$output_file" \
        --evalue "$BLAST_EVALUE" \
        --threads "$DIAMOND_THREADS" \
        --outfmt 6; then

        log_error "diamond blastp execution failed"
        return 1
    fi

    log_info "blastp completed successfully"
    return 0
}