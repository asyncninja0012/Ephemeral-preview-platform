# Ephemeral Preview Environment Platform

Automatically deploy an isolated, containerized preview of your full-stack app for every pull request — and tear it down when the PR closes. Self-hosted, works with any app that runs on Docker Compose.

> **Status:** early build. Not yet functional.

## What it does

- Every `pull_request` gets its own URL (`pr-42.<your-host-ip-dashed>.sslip.io`), its own containers, its own database — isolated from every other open PR on the same host.
- Deploys in under 90 seconds, tears down in under 15.
- 5+ concurrent PR environments on a single small VPS, no port or resource collisions — routing is handled by [Traefik](https://traefik.io/) reading Docker labels, not by juggling host port ranges.
- Two automated merge gates: a [Trivy](https://github.com/aquasecurity/trivy) vulnerability scan on the built image, and a required successful preview deploy on a self-hosted GitHub Actions runner.

## How it's shaped

```
PR opened ──▶ self-hosted runner ──▶ actions/deploy-preview ──▶ Traefik routes pr-<n>.<domain>
PR closed ──▶ self-hosted runner ──▶ actions/teardown-preview ──▶ containers/volumes/network removed
```

Two things ship separately, on purpose:

1. **The automation** — `actions/deploy-preview` and `actions/teardown-preview`, versioned composite GitHub Actions any repo can reference directly.
2. **The infrastructure recipe** — `infra/` (Traefik + a self-hosted runner + a VPS bootstrap script) that each adopting team runs on their *own* small server, since a self-hosted runner can only ever be registered to one repo/org.

Full architecture, isolation strategy, security model, and consumer integration contract are tracked internally (not part of the public repo).

## Using this in your own repo (once tagged `v1`)

1. Stand up the platform host: `infra/cloud-init/vps-bootstrap.sh` on a small VPS (installs Docker, brings up Traefik, registers a self-hosted runner to your repo).
2. Add a `docker-compose.yml` to your repo — internal Docker network only, **no host port publishing** (Traefik reaches your app over the shared network instead).
3. Add a workflow:

   ```yaml
   on:
     pull_request:
       types: [opened, synchronize, reopened, closed]
   jobs:
     preview:
       if: github.event.action != 'closed'
       runs-on: [self-hosted, preview]
       steps:
         - uses: actions/checkout@v4
         - uses: <owner>/ephemeral-preview-platform/actions/deploy-preview@v1
           with:
             compose-file: docker-compose.yml
             app-port: '3000'
             # sslip.io needs the IP dash-separated here — a dotted IP right after a
             # "pr-<n>" prefix parses ambiguously (e.g. pr-99.127.0.0.1 reads as 99.127.0.0)
             base-domain: 127-0-0-1.sslip.io
     teardown:
       if: github.event.action == 'closed'
       runs-on: [self-hosted, preview]
       steps:
         - uses: <owner>/ephemeral-preview-platform/actions/teardown-preview@v1
   ```

## Repo layout

| Path | Purpose |
|---|---|
| `actions/` | The shippable composite GitHub Actions (`deploy-preview`, `teardown-preview`) |
| `infra/` | Traefik, self-hosted runner, and VPS bootstrap for the platform host |
| `scripts/` | Shared shell logic (compose override rendering, health checks, DB seeding) |
| `examples/reference-app` | Minimal fixture app used to dogfood/test the actions |
| `.github/workflows/` | This repo's own CI: Trivy scan gate + self-test of the actions |

## License

[MIT](LICENSE)
