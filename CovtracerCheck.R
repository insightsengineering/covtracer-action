#!/usr/bin/env Rscript
if (!require("covtracer")) {
  remotes::install_github("Genentech/covtracer",
    repos = "https://cloud.r-project.org/", dependencies = TRUE, upgrade = "never"
  )
}

#if (!require("covr")) {
#  install.packages("covr", repos = "https://cloud.r-project.org/", dependencies = TRUE, upgrade = "never")
#}

if (!require("optparse")) {
  install.packages("optparse", repos = "https://cloud.r-project.org/", dependencies = TRUE, upgrade = "never")
}
#if (!require("magrittr")) {
#  install.packages("magrittr", repos = "https://cloud.r-project.org/", dependencies = TRUE, upgrade = "never")
#}
#if (!require("dplyr")) {
#  install.packages("dplyr", repos = "https://cloud.r-project.org/", dependencies = TRUE, upgrade = "never")
#}


library("optparse")
library("covtracer")
library("magrittr")
#library("dplyr")


get_option_list <- function() {
  list(
    make_option("--new-package",
      action = "store_true",
      help = "enable checks specific to new packages"
    ),
    make_option("--no-check-dependencies",
      action = "store_true",
      help = "disable check for bad dependencies"
    ),
    make_option("--no-check-deprecated",
      action = "store_true",
      help = "disable check for usage of deprecated packages"
    ),
    make_option("--no-check-remotes",
      action = "store_true",
      help = "disable check for usage of remote packages other than those hosted on CRAN or Bioconductor"
    ),
    make_option("--no-check-version-num",
      action = "store_true",
      help = "disable check for valid version number"
    ),
    make_option("--no-check-R-ver",
      action = "store_true",
      help = "disable check for valid R version"
    ),
    make_option("--no-check-pkg-size",
      action = "store_true",
      help = "disable check for package tarball size"
    ),
    make_option("--no-check-file-size",
      action = "store_true",
      help = "disable check for individual file size"
    ),
    make_option("--no-check-bioc-views",
      action = "store_true",
      help = "disable biocViews-specific checks (for non-BioC packages)"
    ),
    make_option("--no-check-bbs",
      action = "store_true",
      help = "disable BBS-specific checks (for non-BioC packages). Valid DESCRIPTION"
    ),
    make_option("--no-check-namespace",
      action = "store_true",
      help = "disable namespace checks"
    ),
    make_option("--no-check-vignettes",
      action = "store_true",
      help = "disable vignette checks"
    ),
    make_option("--no-check-library-calls",
      action = "store_true",
      help = "disable check usage of functions that install or update packages"
    ),
    make_option("--no-check-install-self",
      action = "store_true",
      help = "disable check for require or library of itself"
    ),
    make_option("--no-check-coding-practices",
      action = "store_true",
      help = "disable check for some common best coding practices"
    ),
    make_option("--no-check-function-len",
      action = "store_true",
      help = "disable check for function length"
    ),
    make_option("--no-check-man-doc",
      action = "store_true",
      help = "disable checks for man page documentation"
    ),
    make_option("--no-check-news",
      action = "store_true",
      help = "disable checks for NEWS file"
    ),
    make_option("--no-check-unit-tests",
      action = "store_true",
      help = "disable checks for unit tests"
    ),
    make_option("--no-check-skip-bioc-tests",
      action = "store_true",
      help = "disable check for tests that skip when on bioc"
    ),
    make_option("--no-check-formatting",
      action = "store_true",
      help = "disable checks for file formatting"
    ),
    make_option("--no-check-CRAN",
      action = "store_true",
      help = "disable check for if package exists in CRAN"
    ),
    make_option("--no-check-bioc-help",
      action = "store_true",
      help = "disable check for registration on Bioconductor mailing list and support site"
    ),
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
#pkg <- "../../public-github/stageddeps.elecinfra"
options(covr.record_tests = TRUE)
cov <- covr::package_coverage(pkg)

print("-------- cov ------------")
print(cov)

ttdf <- test_trace_df(cov)
print("-------- ttdf -----")
print(ttdf)

traceability_matrix <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(test_name, file) %>%
  dplyr::filter(!duplicated(.)) %>%
  dplyr::arrange(file)

print("------------------------------ traceability_matrix -------------------------------")
print(traceability_matrix)

print("------------------------------ untested_behaviour ------------------------------")
untested_behaviour <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(test_name, count, alias, file) %>%
  dplyr::filter(is.na(count)) %>%
  dplyr::arrange(alias)
print(untested_behaviour)

print("------------------------------ directly_tested ------------------------------")
directly_tested <- ttdf %>%
  dplyr::filter(!doctype %in% c("data", "class")) %>% # ignore objects without testable code
  dplyr::select(direct, alias) %>%
  dplyr::group_by(alias) %>%
  dplyr::summarize(any_direct_tests = any(direct, na.rm = TRUE)) %>%
  dplyr::arrange(alias)

print(directly_tested)
print("------------------------------ end ------------------------------")