#!/usr/bin/env Rscript

library("optparse")
library("covtracer")
library("magrittr")

# list of supported arguments
get_option_list <- function() {
  list(
    make_option("--ignored-file-types",
                help = "ignored file data types (default %default)",
                metavar = "ignored-file-types",
                default = "data,class"
    ),
    make_option("--minimal-coverage",
                type = "integer",
                help = "minimal coverage",
                metavar = "minimal-coverage",
                default = 80
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

# print options to log
message("start_options_list")
message("pkg: ",pkg, "\n")
message("options: ")
# print(opt)
minimal_coverage <- opt[["minimal-coverage"]]
message("minimal_coverage: ", minimal_coverage)
ignored_file_types <- strsplit(opt[["ignored-file-types"]], ",")
message("ignored_file_types: ", ignored_file_types)
message("\nend_options_list\n")


curr_wd <- getwd()
setwd(pkg)
options(covr.record_tests = TRUE)
cov <- covr::package_coverage(".")

setwd(curr_wd)

message("start-covr -----")
write.table(cov, file = ".covtracer_coverage_result.txt", sep = "|",
            row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8",
            quote = FALSE)

print(cov)
message("start-zero_cov -----")
cov_percent <- covr::percent_coverage(cov)
message("Coverage: ", cov_percent)
zero_cov <- covr::zero_coverage(cov)
if (nrow(zero_cov) > 0) {
  write.table(zero_cov, file = ".covr_zero_coverage.txt", sep = "|",
              row.names = TRUE, col.names = NA, na = "NA",
              fileEncoding = "UTF-8", quote = FALSE)
}
print(zero_cov)

# do not create test_trace_df, if zero cov - it generates error about missing data
if (cov_percent > 0) {
  message("start-ttdf -----")
  ttdf <- test_trace_df(cov)
  write.table(ttdf, file = ".covtracer_ttdf.txt", sep = "|",
              row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8",
              quote = FALSE)
  print(ttdf)
  
  message("start-traceability_matrix -----")
  traceability_matrix <- ttdf %>%
    dplyr::filter(!doctype %in% ignored_file_types) %>% # ignore objects without testable code
    dplyr::select(test_name, file) %>%
    dplyr::filter(!duplicated(.)) %>%
    dplyr::arrange(file)
  
  write.table(traceability_matrix, file = ".covtracer_traceability_matrix.txt", sep = "|",
              row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8",
              quote = FALSE)
  
  print(traceability_matrix)
  
  message("start-untested_behaviour -----")
  untested_behaviour <- ttdf %>%
    dplyr::filter(!doctype %in% ignored_file_types) %>% # ignore objects without testable code
    dplyr::select(test_name, count, alias, file) %>%
    dplyr::filter(is.na(count)) %>%
    dplyr::arrange(alias)
  
  print(untested_behaviour)
  if (nrow(untested_behaviour) > 0) {
    write.table(untested_behaviour, file = ".covtracer_untested_behaviour.txt", sep = "|",
                row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8",
                quote = FALSE)
  }
  
  message("start-directly_tested -----")
  directly_tested <- ttdf %>%
    dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
    dplyr::select(direct, alias) %>%
    dplyr::group_by(alias) %>%
    dplyr::summarize(any_direct_tests = any(direct, na.rm = TRUE)) %>%
    dplyr::arrange(alias)
  
  write.table(directly_tested, file = ".covtracer_directly_tested.txt", sep = "|",
              row.names = TRUE, col.names = NA, na = "NA", fileEncoding = "UTF-8",
              quote = FALSE)
  print(directly_tested)
}

# print result of print to file
message("start-coverage_report")
message(paste0("Coverage: ", cov_percent))
print(cov)
if (cov_percent < minimal_coverage) {
  warning( "❌  CovtracerCheck - not enouch covered")
}  
message("end-coverage_report")

setwd(curr_wd)
