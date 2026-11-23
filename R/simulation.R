# Synthetic right-censored survival cohorts for the workshop simulation.
simulate_cohort_v1 <- function(n, seed, event_rate, censor_rate) {
  set.seed(seed, kind = "Mersenne-Twister")
  event <- rexp(n, rate = event_rate)
  censor <- rexp(n, rate = censor_rate)
  data.frame(time = pmin(event, censor), event = as.integer(event <= censor))
}
