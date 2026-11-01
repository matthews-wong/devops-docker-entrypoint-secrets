# devops-docker-entrypoint-secrets

A small POSIX `sh` entrypoint that implements the `*_FILE` convention used by
the official Postgres, MariaDB and WordPress images, so any container can read
secrets from mounted files instead of plain environment variables.

For each `NAME_FILE=/path` in the environment the entrypoint reads the file,
exports its contents as `NAME`, drops `NAME_FILE`, then `exec`s the command so
the application runs as PID 1 and receives signals directly.

## Why

Values passed with `-e` or `environment:` show up in `docker inspect`, in
process listings of the host and in crash dumps. A file mounted from a Docker
or Compose secret (`/run/secrets/...`) does not.

## Usage

```dockerfile
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["myapp"]
```

```yaml
services:
  app:
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
    secrets: [db_password]
```

Rules:

- `NAME_FILE` and `NAME` set together is an error, never a silent override.
- A missing or unreadable file is an error that names the variable and path.
- One trailing newline is stripped, nothing else.
- The secret is never printed.

## Validate

See the `Makefile` once it lands; the checks are `shellcheck`, `hadolint` and a
plain `sh` test script that needs no container runtime.
