#!/usr/bin/env bats

load "${BATS_PLUGIN_PATH}/load.bash"

setup() {
  export WORKDIR="$(mktemp -d)"
  export PLUGIN_DIR="$PWD"
  cd "$WORKDIR"
}

teardown() {
  rm -rf "$WORKDIR"
}

@test "Downloads single file from GitHub" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE=".buildkite/pipeline.yml"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token123"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token123' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token123' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.buildkite/pipeline.yml?ref=abc123 --create-dirs -o .buildkite/pipeline.yml : mkdir -p .buildkite && touch .buildkite/pipeline.yml"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -d ".buildkite" ]
  assert [ -f ".buildkite/pipeline.yml" ]
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
    "-sSfL -H 'Authorization: Bearer token456' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.buildkite/pipeline.yml?ref=def456 --create-dirs -o .buildkite/pipeline.yml : mkdir -p .buildkite && touch .buildkite/pipeline.yml" \
    "-sSfL -H 'Authorization: Bearer token456' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/README.md?ref=def456 --create-dirs -o README.md : touch README.md"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -d ".buildkite" ]
  assert [ -f ".buildkite/pipeline.yml" ]
  assert [ -f "README.md" ]
  unstub curl
}

@test "Fails when GITHUB_TOKEN is missing" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  unset GITHUB_TOKEN

  run "$PLUGIN_DIR/hooks/checkout"

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
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/myorg/myrepo/contents/file.txt?ref=abc123 --create-dirs -o file.txt : touch file.txt"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -f "file.txt" ]
  unstub curl
}

@test "Extracts repo from SSH URL" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="git@github.com:testorg/testrepo.git"
  export BUILDKITE_BRANCH="develop"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/testorg/testrepo/commits/develop : echo '{\"sha\":\"xyz789\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/testorg/testrepo/contents/file.txt?ref=xyz789 --create-dirs -o file.txt : touch file.txt"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -f "file.txt" ]
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
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/workflow.yml?ref=abc123 --create-dirs -o .github/workflow.yml : mkdir -p .github && touch .github/workflow.yml" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/README.md?ref=abc123 --create-dirs -o .github/README.md : mkdir -p .github && touch .github/README.md" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/config.json?ref=abc123 --create-dirs -o .github/config.json : mkdir -p .github && touch .github/config.json"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -d ".github" ]
  assert [ -f ".github/workflow.yml" ]
  assert [ -f ".github/README.md" ]
  assert [ -f ".github/config.json" ]
  unstub curl
}

@test "Exports BUILDKITE_COMMIT with resolved SHA" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"resolved123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/file.txt?ref=resolved123 --create-dirs -o file.txt : touch file.txt"

  run bash -c "source $PLUGIN_DIR/hooks/checkout && echo \$BUILDKITE_COMMIT"

  assert_success
  assert_output --partial "resolved123"
  assert [ -f "file.txt" ]
  unstub curl
}

@test "Skips resolving commit when BUILDKITE_COMMIT already set" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_COMMIT="existing123"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/file.txt?ref=existing123 --create-dirs -o file.txt : touch file.txt"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -f "file.txt" ]
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
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/workflow.yml?ref=abc123 --create-dirs -o .github/workflow.yml : mkdir -p .github && touch .github/workflow.yml" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/.github/README.md?ref=abc123 --create-dirs -o .github/README.md : mkdir -p .github && touch .github/README.md"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert [ -d ".github" ]
  assert [ -f ".github/workflow.yml" ]
  assert [ -f ".github/README.md" ]
  unstub curl
}

@test "Retries on curl failure" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : exit 1" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : exit 1" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/file.txt?ref=abc123 --create-dirs -o file.txt : touch file.txt"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_success
  assert_output --partial "Retrying"
  assert [ -f "file.txt" ]
  unstub curl
}

@test "Fails when ref does not exist" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="file.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="nonexistent"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/nonexistent : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/nonexistent : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/nonexistent : exit 22"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_failure
  assert_output --partial "Failed to resolve ref 'nonexistent'"
  unstub curl
}

@test "Fails when file does not exist" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE="missing.txt"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/missing.txt?ref=abc123 --create-dirs -o missing.txt : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/missing.txt?ref=abc123 --create-dirs -o missing.txt : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/owner/repo/contents/missing.txt?ref=abc123 --create-dirs -o missing.txt : exit 22"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_failure
  assert_output --partial "Failed to download file 'missing.txt'"
  unstub curl
}

@test "Fails when directory does not exist" {
  export BUILDKITE_PLUGIN_GITHUB_FILE_DOWNLOAD_FILE=".nonexistent/*"
  export BUILDKITE_REPO="https://github.com/owner/repo.git"
  export BUILDKITE_BRANCH="main"
  export GITHUB_TOKEN="token"

  stub curl \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/commits/main : echo '{\"sha\":\"abc123\"}'" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/contents/.nonexistent?ref=abc123 : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/contents/.nonexistent?ref=abc123 : exit 22" \
    "-sSfL -H 'Authorization: Bearer token' -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/owner/repo/contents/.nonexistent?ref=abc123 : exit 22"

  run "$PLUGIN_DIR/hooks/checkout"

  assert_failure
  assert_output --partial "Failed to list files for pattern '.nonexistent/*'"
  unstub curl
}
