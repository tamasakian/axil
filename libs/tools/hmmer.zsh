#!/usr/bin/env zsh

function run_hmmsearch() {
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

    if [ -z "$QRY_DOMAIN" ] || [ -z "$REF_FASTA" ] || [ -z "$DB_HMM" ]; then
        log_error "QRY_DOMAIN, REF_FASTA or DB_HMM are missing"
        return 1
    fi

    : ${HMMER_THREADS:=1}
    log_info "use HMMER_THREADS=${HMMER_THREADS}"

    : ${HMMER_CUTOFF:="ga"}
    log_info "use HMMER_CUTOFF=${HMMER_CUTOFF}"

    local ref_fasta="${input_taskdir}/${REF_FASTA}"
    if [ ! -f "$ref_fasta" ]; then
        log_error "reference fasta file not found: ${ref_fasta}"
        return 1
    fi

    local db_hmm="${input_taskdir}/${DB_HMM}"
    if [ ! -f "$db_hmm" ]; then
        log_error "database hmm file not found: ${db_hmm}"
        return 1
    fi

    local timestamp=$(date +"%Y%m%d%H%M%S")
    local output_taskname="P1-run_hmmsearch-${timestamp}"
    local output_taskdir="${TASKS}/${output_taskname}"
    mkdir -p "$output_taskdir"

    local hmm_file="${output_taskdir}/${QRY_DOMAIN}.hmm"
    if ! hmmfetch -o "$hmm_file" "$db_hmm" "$QRY_DOMAIN"; then
        log_error "hmmfetch failed to retrieve profile ${QRY_DOMAIN} from ${db_hmm}"
        return 1
    fi

    local output_file="${output_taskdir}/${QRY_DOMAIN}_${HMMER_CUTOFF}.txt"
    if ! hmmsearch \
        --tblout "$output_file" \
        --cpu "$HMMER_THREADS" \
        --cut_${HMMER_CUTOFF} \
        "$hmm_file" \
        "$ref_fasta"; then

        log_error "hmmsearch execution failed"
        return 1
    fi

    log_info "hmmsearch completed successfully"
    return 0
}