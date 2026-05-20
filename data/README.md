# data/

**This folder does not contain real data.**

Real project data lives on the DS server (or approved Dropbox folder).
Set the path in your personal `config.R`:

```r
data_dir <- "/path/to/your/secure/data"
```

## Teaching dataset

`fake_cohort.csv` is a synthetic dataset for workshop exercises only.
It contains no real patient information.

| Column  | Description                               |
|---------|-------------------------------------------|
| `id`    | Subject ID                                |
| `time`  | Follow-up time in months                  |
| `event` | 1 = event occurred, 0 = censored          |
| `group` | Treatment group (`A` or `B`)              |
| `age`   | Age at baseline (years)                   |
