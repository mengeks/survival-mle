# survival-mle

Kaplan-Meier survival estimation and plotting — workshop demo project.

Repository: <https://github.com/mengeks/survival-mle>

---

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
