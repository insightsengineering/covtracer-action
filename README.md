# Covtracer Action
Github Action based on the Covtracer R package

## Description
GitHub Action based on the [Covtracer](https://github.com/Genentech/covtracer) R package.

Supported R version > 4.x

## Action Type
Composite

## Quick Start

1. Create new action file `.github/workflows/covtracer-check.yaml` and put example content:

```yaml
---
name: CovtracerCheck

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  covtracer:
    runs-on: ubuntu-latest
    name: Covtracer
    container:
      image: rocker/verse:4.1.2
    steps:
      - name: Checkout repo
        uses: actions/checkout@v2

      - name: Run rcmdcheck
        run: |
          R CMD build .
          R CMD INSTALL --with-keep.source *.tar.gz
          R CMD check *.tar.gz

      - name: Run CovtracerCheck
        uses: insightsengineering/covtracer-action@v1
        env:
          GITHUB_PAT: ${{ secrets.MY_PUBLIC_GITHUB_TOKEN }}

```

2. Create PR to test CovtracerCheck action.

## Environment variables

It is preferred to add secret like `MY_PUBLIC_GITHUB_TOKEN`
for repository or organization [(Managing encrypted secrets)](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces)
to avoid GitHub download limit being set to `unauthenticated account`. 


* `GITHUB_PAT`:

  _Description_: Github user [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
                 - token required to read public repositories

  _Required_: `false`


## Inputs

* `path`:

  _Description_: Path to package's root

  _Required_: `false`

  _Default_: `.`

* `allow-failure`:

  _Description_: CovtracerCheck errors will give a warning instead of causing a pipeline failure.

  _Required_: `false`

  _Default_: `false`

* `ignored-file-types`:

  _Description_: CovtracerCheck can ignore non-code file types.

  _Required_: `false`

  _Default_: `data,class`

* `minimal-coverage`:

  _Description_: Minimal coverage threshold.

  _Required_: `false`

  _Default_: `80`

* `post-result-as-comment`:

  _Description_: Post the check result as a PR comment.

  _Required_: `false`

  _Default_: `false`

* `no-cache`:

  _Description_: Disable GitHub Action R dependency caching.

  _Required_: `false`

  _Default_: `false`

