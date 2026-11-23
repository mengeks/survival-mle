# Survival estimate obtained by exponentiating the negative Nelson–Aalen hazard.
method_dependencies <- list(sources = character(), packages = "survival")

estimate_survival <- function(cohort, horizon) {
  fit <- survival::survfit(survival::Surv(time, event) ~ 1,
                          data = cohort, stype = 2, ctype = 1)
  summary(fit, times = horizon, extend = TRUE)$surv[[1]]
}
