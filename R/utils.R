# utils.R -- shared helper functions for survival-mle
# -------------------------------------------------------

#' Check that required columns exist in a data frame
#'
#' @param df   A data.frame.
#' @param cols Character vector of required column names.
#' @return Invisibly returns df; stops with a message if any column is missing.
check_columns <- function(df, cols) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  invisible(df)
}

#' Summarise follow-up time by group
#'
#' @param df       Data frame with columns time, event, group.
#' @param time     Name of the time column (string).
#' @param event    Name of the event indicator column (string).
#' @param group    Name of the grouping column (string).
#' @return A data.frame with median follow-up and event count per group.
summarise_followup <- function(df, time = "time", event = "event",
                                group = "group") {
  check_columns(df, c(time, event, group))
  tapply(seq_len(nrow(df)), df[[group]], function(idx) {
    data.frame(
      group        = df[[group]][idx[1]],
      n            = length(idx),
      events       = sum(df[[event]][idx]),
      median_time  = median(df[[time]][idx])
    )
  }) |> do.call(what = rbind)
}
