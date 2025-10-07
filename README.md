# GitHub File Download Buildkite Plugin

> [!WARNING]
>
> This is a proof of concept, DO NOT depend on it yet.

Downloads files from GitHub repositories.

## Why

Sometimes you only need to access a couple of files, and you don't want to delay your build waiting for a massive git clone.

> [!NOTE]
>
> The jobs will be subject to Github API rate limits so use sparingly.

## Example

```yaml
steps:
  - command: buildkite agent upload
    plugins:
      - github-file-download#v1.0.0:
          file: .buildkite/pipeline.yml
```

```yaml
steps:
  - command: scripts/some-script.sh
    plugins:
      - github-file-download#v1.0.0:
          file:
            - scripts/*
```

## Configuration

### `file` (required)

The path to the file in the repository.

## Developing

To run the tests:

```bash
docker-compose run --rm tests
```

To run the tests:

```bash
docker-compose run --rm lint
```

## License

MIT
