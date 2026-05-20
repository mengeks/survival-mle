# config_template.R  <- commit this file to GitHub
# -------------------------------------------------------
# Each person: copy this file to config.R and fill in
# your own local paths. config.R is in .gitignore --
# do NOT commit config.R.
# -------------------------------------------------------

library(here)

# Path to the project data on your machine
# (the fake teaching dataset lives in data/ inside the repo)
data_dir <- here("data")           # default: use the repo's data/ folder
# data_dir <- "/path/to/your/secure/data"   # uncomment for real data

# Where to save figures and tables
output_dir <- here("output")

# Your initials (optional -- used to label personal output files)
user_id <- "your_initials"
