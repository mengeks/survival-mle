method_dependencies <- list(sources = "R/fit-km.R", packages = "survival")

estimate_survival <- function(cohort, horizon) {
  summary(fit_km(cohort), times = horizon, extend = TRUE)$surv[[1]]
}
