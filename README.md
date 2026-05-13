# axil

`axil` is a small zsh-based bioinformatics workflow toolkit. It wraps common
third-party command-line tools, including DIAMOND, HMMER, MCScanX, and
`duplicate_gene_classifier`, into reproducible task directories under
`$HOME/axil/tasks`.

The current focus is pairwise synteny analysis with MCScanX and related
protein-search utilities.

## Repository Layout

```text
axil/
|-- jobs/
|   `-- profile.zsh          # Defines ROOT, JOBS, LIBS, and TASKS
|-- libs/
|   |-- tools/
|   |   |-- diamond.zsh      # DIAMOND blastp wrappers
|   |   |-- hmmer.zsh        # HMMER hmmfetch/hmmsearch wrapper
|   |   `-- mcscanx.zsh      # MCScanX preparation and execution wrappers
|   `-- utils/
|       `-- io.zsh           # Logging and config loading helpers
`-- tasks/                   # Ignored working directory for inputs and outputs
```

Most runtime data are intentionally ignored by git. Put input datasets and
generated outputs under `tasks/`.

## Requirements

- zsh
- DIAMOND, available as `diamond`
- HMMER, available as `hmmfetch` and `hmmsearch`
- MCScanX, available as `MCScanX`
- MCScanX duplicate gene classifier, available as `duplicate_gene_classifier`

Install these tools separately and make sure they are available on `PATH`
before running the wrappers.

## Setup

Clone or place this repository at `$HOME/axil`, then load the shared profile and
tool libraries in a zsh session:

```zsh
source ~/axil/jobs/profile.zsh
source ~/axil/libs/utils/io.zsh
source ~/axil/libs/tools/diamond.zsh
source ~/axil/libs/tools/hmmer.zsh
source ~/axil/libs/tools/mcscanx.zsh
```

The profile defines:

- `ROOT=$HOME/axil`
- `JOBS=$ROOT/jobs`
- `LIBS=$ROOT/libs`
- `TASKS=$ROOT/tasks`

## Task Directory Convention

Each analysis starts from an input task directory:

```text
tasks/<task-name>/
|-- config.zsh
|-- species_a.fasta
|-- species_b.fasta
|-- species_a.gff
`-- species_b.gff
```

Every wrapper reads `tasks/<task-name>/config.zsh`, writes a timestamped output
directory under `tasks/`, and logs progress to the terminal.

## MCScanX Pairwise Workflow

Create a `config.zsh` file with a zsh array named `SPECIES_LIST`:

```zsh
SPECIES_LIST=(species_a species_b species_c)
DIAMOND_THREADS=4
```

For each species name, provide matching FASTA and GFF files:

```text
tasks/example/
|-- config.zsh
|-- species_a.fasta
|-- species_a.gff
|-- species_b.fasta
|-- species_b.gff
|-- species_c.fasta
`-- species_c.gff
```

Run DIAMOND all-vs-pairwise protein searches for every species pair:

```zsh
blastp_for_mcscanx example
```

This creates:

```text
tasks/P1-blastp_for_mcscanx-YYYYMMDDHHMMSS/<species_i>__<species_j>/<pair>.blast
```

Concatenate pairwise GFF files for MCScanX:

```zsh
concat_gff_for_mcscanx example
```

This creates:

```text
tasks/P2-concat_gff_for_mcscanx-YYYYMMDDHHMMSS/<species_i>__<species_j>/<pair>.gff
```

Run MCScanX using the original config task, the DIAMOND output task, and the GFF
output task:

```zsh
run_mcscanx example P1-blastp_for_mcscanx-YYYYMMDDHHMMSS P2-concat_gff_for_mcscanx-YYYYMMDDHHMMSS
```

Run the MCScanX duplicate gene classifier with the same input structure:

```zsh
run_classifier example P1-blastp_for_mcscanx-YYYYMMDDHHMMSS P2-concat_gff_for_mcscanx-YYYYMMDDHHMMSS
```

## Standalone DIAMOND blastp

For a two-file DIAMOND search, create a task directory with `config.zsh`:

```zsh
REF_FASTA=reference.fasta
QRY_FASTA=query.fasta
DIAMOND_THREADS=4
BLAST_EVALUE=1e-5
MAX_TARGET_SEQS=25
QUERY_COVER=80
```

Then run:

```zsh
run_blastp <task-name>
```

The wrapper creates a DIAMOND database from `REF_FASTA` and writes tabular
BLAST format 6 results to:

```text
tasks/P1-run_blastp-YYYYMMDDHHMMSS/blastp.results
```

## HMMER hmmsearch

For HMMER searches, create a task directory with `config.zsh`:

```zsh
QRY_DOMAIN=PF00000
REF_FASTA=proteins.fasta
DB_HMM=Pfam-A.hmm
HMMER_THREADS=4
HMMER_CUTOFF=ga
```

Then run:

```zsh
run_hmmsearch <task-name>
```

The wrapper fetches the requested HMM profile with `hmmfetch`, runs
`hmmsearch`, and writes the table output to a timestamped task directory.

## Notes

- All task names passed to functions are resolved relative to `$TASKS`.
- Missing pairwise input files are skipped with warnings in the MCScanX
  workflow.
- Generated task directories are ignored by git through `.gitignore`.
- This project is intentionally lightweight: source the zsh files you need, then
  run the function for the analysis step you want.
