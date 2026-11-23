script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[[1]])
root <- dirname(dirname(normalizePath(script, mustWork = TRUE)))
source(file.path(root, "R/simulation-workflow.R"))
simulation_cli("run", root)
