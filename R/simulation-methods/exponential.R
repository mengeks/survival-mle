method_dependencies <- list(sources = character(), packages = character())

estimate_survival <- function(cohort, horizon) {
  hazard <- sum(cohort$event) / sum(cohort$time)
  exp(-horizon * hazard)
}
