# Shared implementation for the simulation and saved-results summary CLIs.

load_simulation_config <- function(path, ancestors = character()) {
  path <- normalizePath(path, mustWork = TRUE)
  if (path %in% ancestors) stop("Circular config inheritance: ", path)
  config <- yaml::read_yaml(path, eval.expr = FALSE)
  if (!is.list(config) || is.null(names(config)) || anyDuplicated(names(config))) {
    stop("Config must be a mapping with unique keys: ", path)
  }
  parent <- config$extends
  if (is.null(parent)) return(config)
  if (!is.character(parent) || length(parent) != 1L || !nzchar(parent) ||
      startsWith(parent, "/")) stop("extends must be a relative config path")
  config$extends <- NULL
  defaults <- load_simulation_config(file.path(dirname(path), parent), c(ancestors, path))
  utils::modifyList(defaults, config)
}

validate_simulation_config <- function(cfg) {
  required <- c("n_reps", "seed", "horizon", "event_rate", "censor_rate", "sample_sizes", "methods")
  if (!setequal(names(cfg), required)) {
    stop("Missing config keys: ", paste(setdiff(required, names(cfg)), collapse = ", "),
         ". Unknown keys: ", paste(setdiff(names(cfg), required), collapse = ", "))
  }
  n <- unlist(cfg$sample_sizes)
  if (!is.numeric(n) || !length(n) || any(!is.finite(n)) ||
      any(n < 2 | n > .Machine$integer.max | n %% 1 != 0) || anyDuplicated(n)) {
    stop("sample_sizes must contain unique integers of at least 2")
  }
  methods <- unlist(cfg$methods)
  if (!is.character(methods) || !length(methods) || anyNA(methods) || anyDuplicated(methods) ||
      any(!grepl("^[a-z][a-z0-9_]*$", methods))) stop("Invalid or duplicate method names")
  for (key in c("n_reps", "seed", "horizon", "event_rate", "censor_rate")) {
    value <- cfg[[key]]
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) stop("Invalid ", key)
  }
  if (cfg$n_reps < 1 || cfg$n_reps > .Machine$integer.max || cfg$n_reps %% 1 != 0 ||
      cfg$seed < 0 || cfg$seed > .Machine$integer.max || cfg$seed %% 1 != 0 ||
      cfg$horizon <= 0 || cfg$event_rate <= 0 || cfg$censor_rate <= 0) {
    stop("Expected integer replication count and seed, and positive horizon and rates")
  }
  cfg$sample_sizes <- sort(as.integer(n))
  cfg$methods <- sort(methods)
  cfg
}

simulation_cli <- function(mode, root) {
  args <- commandArgs(trailingOnly = TRUE)
  usage <- paste(
    "Options: --config PATH (default configs/default.yaml),",
    "--out PATH (default output/simulation)",
    if (mode == "run") ", --sample-size N, --method NAME" else ""
  )
  if ("--help" %in% args) {
    cat(usage, "\n")
    return(invisible(NULL))
  }
  keys <- args[seq_along(args) %% 2 == 1]
  allowed <- c("--config", "--out", if (mode == "run") c("--sample-size", "--method"))
  if (length(args) %% 2 != 0 || anyDuplicated(keys) || !all(keys %in% allowed)) stop(usage)
  opts <- setNames(as.list(args[seq_along(args) %% 2 == 0]), keys)
  path <- function(option, default) {
    value <- opts[[option]]
    if (is.null(value)) value <- default
    if (startsWith(value, "/")) value else file.path(root, value)
  }
  config <- path("--config", "configs/default.yaml")
  cfg <- validate_simulation_config(load_simulation_config(config))
  sample_sizes <- cfg$sample_sizes
  if (!is.null(opts[["--sample-size"]])) {
    value <- opts[["--sample-size"]]
    if (!grepl("^[0-9]+$", value) || !as.numeric(value) %in% sample_sizes) {
      stop("Sample size is outside the config: ", value)
    }
    sample_sizes <- as.integer(value)
  }
  methods <- cfg$methods
  if (!is.null(opts[["--method"]])) {
    value <- opts[["--method"]]
    if (!value %in% methods) stop("Method is outside the config: ", value)
    methods <- value
  }
  execute_simulation(mode, root, path("--out", "output/simulation"), config,
                     cfg, sample_sizes, methods)
}

hash_file <- function(path) digest::digest(file = path, algo = "sha256")
hash_value <- function(value) digest::digest(value, algo = "sha256", serializeVersion = 2)
short_hash <- function(value) substr(hash_value(value), 1, 16)

load_simulation_method <- function(method, root, horizon) {
  relative <- file.path("R/simulation-methods", paste0(method, ".R"))
  path <- file.path(root, relative)
  if (!file.exists(path)) stop("Missing method implementation: ", method)
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  dependencies <- env$method_dependencies
  for (source in dependencies$sources) sys.source(file.path(root, source), envir = env)
  sources <- sort(c(relative, dependencies$sources))
  packages <- sort(dependencies$packages)
  list(estimate = env$estimate_survival, spec = list(
    fit_contract = "survival_at_horizon_v1", method = method, horizon = horizon,
    sources = setNames(lapply(sources, function(p) hash_file(file.path(root, p))), sources),
    packages = setNames(lapply(packages, function(p) as.character(utils::packageVersion(p))), packages),
    r_version = as.character(getRversion())
  ))
}

publish_file <- function(path, write) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temp <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(temp))
  write(temp)
  if (!file.rename(temp, path)) stop("Could not publish ", path)
}

read_or_compute <- function(path, label, key, revision, produce = NULL) {
  if (file.exists(path)) {
    record <- tryCatch(readRDS(path), error = function(e) stop("Unreadable result for ", label, ": ", path))
    if (!identical(record$scientific_setting, key) || !identical(record$status, "complete") ||
        !identical(record$payload_sha256, hash_value(record$payload))) {
      stop("Incompatible or corrupted result for ", label, ": ", path)
    }
    return(list(value = record$payload, reused = TRUE))
  }
  if (is.null(produce)) stop("Missing requested result: ", label)
  started <- proc.time()[["elapsed"]]
  payload <- produce()
  record <- list(
    scientific_setting = key, status = "complete", payload = payload,
    payload_sha256 = hash_value(payload), git_commit = revision,
    completed_at = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"),
    runtime_seconds = proc.time()[["elapsed"]] - started
  )
  publish_file(path, function(temp) saveRDS(record, temp, version = 2))
  list(value = payload, reused = FALSE)
}

execute_simulation <- function(mode, root, out, config_path, cfg, sample_sizes, methods) {
  dgp_source <- file.path(root, "R/simulation.R")
  dgp_env <- new.env(parent = globalenv())
  sys.source(dgp_source, envir = dgp_env)
  dgp_sha <- hash_file(dgp_source)
  implementations <- setNames(lapply(methods, load_simulation_method, root = root,
                                     horizon = cfg$horizon), methods)
  revision <- tryCatch(
    suppressWarnings(system2("git", c("-C", shQuote(root), "rev-parse", "HEAD"),
                            stdout = TRUE, stderr = FALSE))[[1]],
    error = function(e) NA_character_
  )
  started <- proc.time()[["elapsed"]]
  stats <- c(data_new = 0L, data_reused = 0L, fits_new = 0L, fits_reused = 0L)
  rows <- list()

  for (n in sample_sizes) {
    dgp <- list(name = "exponential_censoring_v1", n = n, event_rate = cfg$event_rate,
                censor_rate = cfg$censor_rate, seed_base = cfg$seed,
                r_version = as.character(getRversion()), dgp_sha256 = dgp_sha,
                rng = c("Mersenne-Twister", "seed_from_setting_and_rep_v1"))
    setting_root <- file.path(out, paste0("n_", n), short_hash(dgp))
    for (rep in seq_len(cfg$n_reps)) {
      seed <- strtoi(substr(hash_value(list(dgp, rep)), 1, 7), 16L)
      label <- sprintf("rep_%03d.rds", rep)
      cohort_meta <- list(dgp = dgp, replicate = rep, seed = seed)
      cohort <- read_or_compute(
        file.path(setting_root, "data", label), sprintf("n=%s rep=%s cohort", n, rep),
        cohort_meta, revision, if (mode == "run") {
          function() dgp_env$simulate_cohort_v1(n, seed, cfg$event_rate, cfg$censor_rate)
        }
      )
      key <- if (cohort$reused) "data_reused" else "data_new"
      stats[[key]] <- stats[[key]] + 1L
      for (method in methods) {
        impl <- implementations[[method]]
        key <- list(cohort = cohort_meta, cohort_sha256 = hash_value(cohort$value), method = impl$spec)
        result <- read_or_compute(
          file.path(setting_root, "fits", method, short_hash(impl$spec), label),
          sprintf("n=%s method=%s rep=%s", n, method, rep), key, revision,
          if (mode == "run") function() impl$estimate(cohort$value, cfg$horizon)
        )
        stopifnot(is.numeric(result$value), length(result$value) == 1L,
                  is.finite(result$value), result$value >= 0, result$value <= 1)
        key <- if (result$reused) "fits_reused" else "fits_new"
        stats[[key]] <- stats[[key]] + 1L
        rows[[length(rows) + 1L]] <- data.frame(n = n, method = method, rep = rep,
                                               seed = seed, estimate = result$value)
      }
    }
  }

  if (mode == "summarize") {
    raw <- do.call(rbind, rows)
    stopifnot(nrow(raw) == length(cfg$sample_sizes) * length(cfg$methods) * cfg$n_reps,
              !anyDuplicated(raw[c("n", "method", "rep")]))
    truth <- exp(-cfg$event_rate * cfg$horizon)
    raw$error <- raw$estimate - truth
    raw$squared_error <- raw$error^2
    summary <- aggregate(cbind(estimate, error, squared_error) ~ n + method, data = raw, FUN = mean)
    names(summary)[3:5] <- c("mean_survival", "bias", "mse")
    summary$truth <- truth
    summary$replications <- cfg$n_reps
    publish_file(file.path(out, "replicates.csv"), function(tmp) write.csv(raw, tmp, row.names = FALSE))
    publish_file(file.path(out, "summary.csv"), function(tmp) write.csv(summary, tmp, row.names = FALSE))
  }
  receipt <- list(
    operation = mode, config = config_path, configuration = cfg,
    selected_sample_sizes = sample_sizes, selected_methods = methods,
    counts = as.list(stats), status = "complete", git_commit = revision,
    runtime_seconds = proc.time()[["elapsed"]] - started,
    completed_at = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
  )
  journal <- file.path(out, "runs")
  dir.create(journal, recursive = TRUE, showWarnings = FALSE)
  receipt_path <- tempfile(paste0(mode, "-"), tmpdir = journal, fileext = ".json")
  publish_file(receipt_path, function(tmp) jsonlite::write_json(receipt, tmp, auto_unbox = TRUE, pretty = TRUE))
  cat(paste(names(stats), stats, sep = "=", collapse = " "), "\n", sep = "")
  cat("Run record: ", receipt_path, "\n", sep = "")
  if (mode == "summarize") cat("Summary: ", file.path(out, "summary.csv"), "\n", sep = "")
}
