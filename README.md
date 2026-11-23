# survival-mle

Kaplan-Meier survival estimation and plotting — workshop demo project.

Repository: <https://github.com/mengeks/survival-mle>

---

## Incremental simulation demo

This workshop demo generates synthetic right-censored cohorts. It compares
Kaplan–Meier, an exponential survival model, and a Nelson–Aalen survival
estimate at two months. The original data analysis is described below.

Install the simulation dependencies once if needed:

```sh
Rscript --vanilla -e 'install.packages(c("survival", "yaml", "digest", "jsonlite"), repos = "https://cloud.r-project.org")'
```

Run the three steps from the repo root. They use the same result directory.

```sh
bash experiments/run_experiment.sh
bash experiments/run_experiment.sh --config configs/add_size.yaml --sample-size 150
bash experiments/run_experiment.sh --config configs/add_method.yaml --method method_c
Rscript --vanilla scripts/summarize.R --config configs/add_method.yaml
```

The size override adds 150 patients to the original grid of 50 and 100.
The method override inherits that expanded grid and adds the new method in
`R/simulation-methods/method_c.R`. The summary validates the entire grid
before writing `output/simulation/summary.csv` and `replicates.csv`.
The `runs/` subfolder records the resolved configurations and counts; cohort
and method records have their own identities and checksums.

A clean full run can use the final config directly:

```sh
bash experiments/run_experiment.sh --config configs/add_method.yaml
Rscript --vanilla scripts/summarize.R --config configs/add_method.yaml
```

Use `--out /path/to/results` on both commands to build in a separate directory.
For a short check of actual cache reuse, rejection of a missing fit, and
agreement with the clean full run:

```sh
bash tests/check_incremental_simulation.sh
```

## Setup

1. Clone the repo and open `survival-mle.Rproj` in RStudio.

2. Copy `config_template.R` to `config.R` and fill in your local paths:
   ```r
   data_dir   <- "/path/to/your/local/data"
   output_dir <- here::here("output")   # default is fine for most people
   user_id    <- "your_initials"
   ```
   `config.R` is gitignored — **do not commit it**.

3. Restore packages from the lockfile:
   ```r
   renv::restore()
   ```

4. Run the analysis:
   ```r
   source(here::here("analysis", "01-fit-model.R"))
   ```

---

## Data location

**Data is not stored in this repo.**

Place the project data at the path you set in `config.R → data_dir`.
A fake teaching dataset is provided in `data/fake_cohort.csv` for
workshop exercises only.

Columns in `fake_cohort.csv`:

| Column  | Description                            |
|---------|----------------------------------------|
| `id`    | Subject ID (integer)                   |
| `time`  | Follow-up time in months               |
| `event` | Event indicator (1 = event, 0 = censored) |
| `group` | Treatment group (`A` or `B`)           |
| `age`   | Age at baseline (years)               |

---

## Project layout

```
survival-mle/
|-- survival-mle.Rproj
|-- README.md
|-- .gitignore
|-- config_template.R     # copy to config.R; fill in local paths
|-- renv.lock             # locked package versions
|-- R/
|   |-- fit-km.R          # Kaplan-Meier estimation functions
|   `-- utils.R           # helper utilities
|-- analysis/
|   `-- 01-fit-model.R    # main analysis script
|-- data/
|   `-- README.md         # data documentation (data itself is not here)
`-- output/               # figures and tables (gitignored)
```

---

## Conventions

- All paths use `here()` — never `setwd()` or absolute paths.
- Packages managed with `renv`; commit `renv.lock` whenever packages change.
- Commit messages: verb + what (e.g. `add Kaplan-Meier plot for group B`).
- Each collaborator works on a named branch: `git checkout -b yourname/feature`.
