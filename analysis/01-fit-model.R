# 01-fit-model.R
# Kaplan-Meier survival analysis -- workshop demo
# -------------------------------------------------------

library(here)
source(here("config.R"))          # loads data_dir, output_dir, user_id
source(here("R", "utils.R"))
source(here("R", "fit-km.R"))

# ---- 1. Load data ----
dat_path <- file.path(data_dir, "fake_cohort.csv")
if (!file.exists(dat_path)) {
  stop(
    "Data file not found: ", dat_path,
    "\nCheck that data_dir is set correctly in config.R"
  )
}
dat <- read.csv(dat_path)
cat("Loaded", nrow(dat), "rows from", dat_path, "\n")

# ---- 2. Quick data summary ----
print(summarise_followup(dat))

# ---- 3. Fit Kaplan-Meier curves ----
# Overall
km_overall <- fit_km(dat)

# By group
km_by_group <- fit_km(dat, group = "group")

# ---- 4. Plot and save ----
out_file <- file.path(output_dir, paste0("km_by_group_", user_id, ".png"))
png(out_file, width = 800, height = 600, res = 120)
plot_km(km_by_group, title = "KM Curves by Treatment Group")
dev.off()
cat("Saved plot to:", out_file, "\n")

# ---- 5. Print median survival times ----
print(km_by_group)
