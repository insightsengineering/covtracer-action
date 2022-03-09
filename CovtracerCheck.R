#!/usr/bin/env Rscript

library("optparse")
library("covtracer")
library("magrittr")

get_option_list <- function() {
  list(
    make_option("--build-output-file",
      type = "character",
      help = "file containing R CMD build output, for additional analysis",
      metavar = "build-output-file"
    ),
    make_option("--quit-with-status",
      action = "store_true",
      help = "enable exit code option when performing check"
    )
  )
}

get_arg_parser <- function() {
  option_list <- get_option_list()
  OptionParser(
    usage = "R CMD CovtracerCheck [options] package",
    option_list = option_list
  )
}

usage <- function() {
  optparse::print_help(get_arg_parser())
}


parser <- get_arg_parser()
tryCatch(
  expr = {
    arguments <- parse_args(parser, positional_arguments = 1)
  },
  error = function(err) {
    stop("Bad Command Line Option\n", "See './CovtracerCheck.R --help'")
  }
)
opt <- arguments$options
pkg <- arguments$args

opt$Called_from_command_line <- TRUE # nolint

print("opt content:")
print(opt)
print("pkg: ")
print(pkg)
options(covr.record_tests = TRUE)
cov <- covr::package_coverage(pkg)
write.table(cov, file = ".covtracer_coverage_result.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8", quote=FALSE )
print(cov)


ttdf <- test_trace_df(cov)
print("-------- ttdf -----")

write.table(ttdf, file = ".ttdf.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8", quote=FALSE )
print(ttdf)

print("------------------------------ traceability_matrix -------------------------------")
traceability_matrix <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(test_name, file) %>%
  dplyr::filter(!duplicated(.)) %>%
  dplyr::arrange(file)

write.table(traceability_matrix, file = ".covtracer_traceability_matrix.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8", quote=FALSE)

print(traceability_matrix)

print("------------------------------ untested_behaviour ------------------------------")
untested_behaviour <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(test_name, count, alias, file) %>%
  dplyr::filter(is.na(count)) %>%
  dplyr::arrange(alias)

write.table(untested_behaviour, file = ".covtracer_untested_behaviour.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8", quote=FALSE )
print(untested_behaviour)

print("------------------------------ directly_tested ------------------------------")
directly_tested <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(direct, alias) %>%
  dplyr::group_by(alias) %>%
  dplyr::summarize(any_direct_tests = any(direct, na.rm = TRUE)) %>%
  dplyr::arrange(alias)

write.table(directly_tested, file = ".covtracer_directly_tested.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8", quote=FALSE )

print(directly_tested)
print("------------------------------ end ------------------------------")