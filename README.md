# covtracer-action
Github Action based on the Covtracer R package

## Description
Github Action to implement check details from  R package checks with [Covtracer](https://github.com/Genentech/covtracer).

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

jobs:
  covtracer-check:
    runs-on: ubuntu-latest
    name: CovtracerCheck
    container:
      image: rocker/verse:4.1.0
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
          GITHUB_TOKEN: ${{ secrets.MY_PUBLIC_GITHUB_TOKEN }}

```

2. Create PR to test CovtracerCheck action.

## Environment variables

it is preferred to add secret like for example `MY_PUBLIC_GITHUB_TOKEN`
for repository or organization [Manage secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces). 
Related to avoid Github download limit set to `unathenticated account`. 

<details>
<summary>Rate limit error details</summary>

```

Using bundled GitHub PAT. Please add your own PAT to the env var `GITHUB_PAT`
Error: Failed to install 'unknown package' from GitHub:
  HTTP error 401.
  Bad credentials

  Rate limit remaining: 59/60
  Rate limit reset at: 2022-03-09 09:59:22 UTC

```

</details>


* `GITHUB_TOKEN`:

  _Description_: Github user [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
                 - token required to read public repositories

  _Required_: `false`


## Inputs

* `path`:

  _Description_: Path to package's root

  _Required_: `false`

  _Default_: `.`

* `allow-failure`:

  _Description_: CovtracerCheck errors will not fail, but will give a warning.

  _Required_: `false`

  _Default_: `false`

* `ignored-file-types`:

  _Description_: CovtracerCheck can ignore none code file types.

  _Required_: `false`

  _Default_: `data,class`

* `minimal-coverage`:

  _Description_: Minimal coverage.

  _Required_: `false`

  _Default_: `80`

* `post-result-as-comment`:

  _Description_: post the check result as a PR comment.

  _Required_: `false`

  _Default_: `false`

* `no-cache`:

  _Description_: disable github action R dependency caching.

  _Required_: `false`

  _Default_: `false`

