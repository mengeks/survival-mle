# fit-km.R -- Kaplan-Meier estimation helpers
# -------------------------------------------------------
# Requires: survival

#' Fit a Kaplan-Meier curve
#'
#' @param df      Data frame with time, event, and (optionally) group columns.
#' @param time    Name of the time column.
#' @param event   Name of the event indicator column (1 = event, 0 = censored).
#' @param group   Name of the group column, or NULL for overall curve.
#' @return A survfit object.
fit_km <- function(df, time = "time", event = "event", group = NULL) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("Package 'survival' is required. Run: renv::install('survival')")
  }
  source_vars <- c(time, event)
  if (!is.null(group)) source_vars <- c(source_vars, group)
  for (v in source_vars) {
    if (!v %in% names(df)) stop("Column not found in data: ", v)
  }

  surv_obj <- survival::Surv(time = df[[time]], event = df[[event]])

  if (is.null(group)) {
    survival::survfit(surv_obj ~ 1, data = df)
  } else {
    frm <- as.formula(paste("surv_obj ~", group))
    survival::survfit(frm, data = df)
  }
}

#' Plot a Kaplan-Meier curve (base R)
#'
#' @param fit     A survfit object from fit_km().
#' @param title   Plot title.
#' @param ...     Additional arguments passed to plot.survfit.
plot_km <- function(fit, title = "Kaplan-Meier Survival Curve", ...) {
  plot(
    fit,
    xlab  = "Time (months)",
    ylab  = "Survival probability",
    main  = title,
    col   = seq_along(fit$strata),
    lwd   = 2,
    conf.int = TRUE,
    ...
  )
  if (!is.null(fit$strata)) {
    legend(
      "topright",
      legend = names(fit$strata),
      col    = seq_along(fit$strata),
      lwd    = 2,
      bty    = "n"
    )
  }
}
