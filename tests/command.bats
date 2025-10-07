#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

@test "Downloads single file from GitHub" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE=".buildkite/pipeline.yml"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token123"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token123' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token123' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.buildkite/pipeline.yml?ref=abc123 -o .buildkite/pipeline.yml : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Downloads multiple files from GitHub" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE_0=".buildkite/pipeline.yml"
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE_1="README.md"
  export BUILDKITE_REPO="git@github.com:owner/repo.git"
  export BUILDKITE_BRANCH="feature-branch"
  export GITHUB_TOKEN="token456"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token456' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/feature-branch : echo '{\"sha\":\"def456\"}'" \
    "-sSfL -H 'Authorization: Bearer token456' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.buildkite/pipeline.yml?ref=def456 -o .buildkite/pipeline.yml : echo 'downloaded'" \
    "-sSfL -H 'Authorization: Bearer token456' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/README.md?ref=def456 -o README.md : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Fails when GITHUB_TOKEN is missing" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  unset GITHUB_TOKEN

  run "$PWD/hooks/checkout"

  assert_failure
  assert_output --partial "GITHUB_TOKEN is required"
}

@test "Extracts repo from HTTPS URL" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/myorg/myrepo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/myorg/myrepo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/myorg/myrepo/contents/file.txt?ref=abc123 -o file.txt : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Extracts repo from SSH URL" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="git@github.com:testorg/testrepo.git"
  export BUILDKITE_BRANCH="develop"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/testorg/testrepo/commits/develop : echo '{\"sha\":\"xyz789\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/testorg/testrepo/contents/file.txt?ref=xyz789 -o file.txt : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Downloads all files in directory with /* pattern" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE=".github/*"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/contents/.github?ref=abc123 : echo '[{\"path\":\".github/workflow.yml\",\"type\":\"file\"},{\"path\":\".github/README.md\",\"type\":\"file\"},{\"path\":\".github/config.json\",\"type\":\"file\"}]'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/workflow.yml?ref=abc123 -o .github/workflow.yml : echo 'downloaded'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/README.md?ref=abc123 -o .github/README.md : echo 'downloaded'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/config.json?ref=abc123 -o .github/config.json : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Exports BUILDKITE_COMMIT with resolved SHA" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"resolved123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/file.txt?ref=resolved123 -o file.txt : echo 'downloaded'"

  run bash -c "source $PWD/hooks/checkout && echo \$BUILDKITE_COMMIT"

  assert_success
  assert_output --partial "resolved123"
  unstub curl
}

@test "Skips resolving commit when BUILDKITE_COMMIT already set" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_COMMIT="existing123"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/file.txt?ref=existing123 -o file.txt : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}

@test "Filters out directories when listing files" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE=".github/*"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/contents/.github?ref=abc123 : echo '[{\"path\":\".github/workflow.yml\",\"type\":\"file\"},{\"path\":\".github/subdir\",\"type\":\"dir\"},{\"path\":\".github/README.md\",\"type\":\"file\"}]'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/workflow.yml?ref=abc123 -o .github/workflow.yml : echo 'downloaded'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/README.md?ref=abc123 -o .github/README.md : echo 'downloaded'"

  run "$PWD/hooks/checkout"

  assert_success
  unstub curl
}
