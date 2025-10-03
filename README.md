# GitHub File Download Buildkite Plugin

Downloads files from GitHub repositories.

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
  - command: ls -la
    plugins:
      - github-file-download#v1.0.0:
          file:
            - .github/*
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
