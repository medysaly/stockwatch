# stockwatch

[![CI](https://github.com/medysaly/stockwatch/actions/workflows/ci.yml/badge.svg)](https://github.com/medysaly/stockwatch/actions/workflows/ci.yml)

An AI-powered stock market companion that fetches real price and news data, summarizes it with Claude, and runs automatically in AWS on a daily schedule.

This is a **learning project**, not a polished product — it's the vehicle for hands-on practice with AI engineering, AWS, Docker, and Terraform, built by someone studying toward an AI/ML engineering role. Every architectural choice here was made twice: once for the app, once for the lesson. That framing is intentional and stays in this README rather than being hidden — the discipline of building something real, debugging it end to end, and documenting the actual cost/architecture tradeoffs is the point.

## What it does

For a given stock ticker (currently hardcoded to `AAPL`, by design — see Status below):

1. Pulls the last 5 days of price history and the most recent news headlines via `yfinance`.
2. Sends that data to Claude (Anthropic API) with a prompt engineered to produce a concise, grounded market summary.
3. Logs the prompt, response, latency, and token usage as structured JSON for observability.
4. Runs this whole pipeline automatically once a day, with zero manual intervention, as a container deployed on AWS Lambda.

## Architecture

```
EventBridge (daily schedule)
        │ triggers, passing {"ticker": "AAPL"}
        ▼
Lambda (container image, arm64, Python 3.12)
   ├─ pulls image from: ECR
   ├─ reads API key from: Secrets Manager (one bundled secret)
   ├─ fetches: stock price + news via yfinance
   ├─ calls: Claude API → summary
   └─ logs: prompt, response, latency, token cost → CloudWatch
        │
        ▼
   (future) S3 — storing raw news/summary data
```

Everything above is provisioned as code via Terraform (`infra/`) — nothing was clicked into existence in the AWS console.

## Tech stack, and why

| Choice | Why |
|---|---|
| **Python 3.12** | Not 3.11 — AWS Lambda's Python 3.12+ base images run on Amazon Linux 2023, which has a newer `glibc` than the Amazon Linux 2 base under 3.11. Modern compiled packages (`numpy`/`pandas`, pulled in by `yfinance`) only ship wheels for the newer `glibc`; this was discovered the hard way, deploying to Lambda. |
| **uv** | Fast, lockfile-based dependency management — replaces `pip` + `venv` + `pyenv` in one tool. |
| **Docker** | AWS Lambda's container-image deployment path, needed once dependencies got non-trivial (`yfinance`, `anthropic`, `boto3`). |
| **Terraform** (not CDK/SAM) | Chosen deliberately over AWS-native IaC tools — appears in significantly more job postings, and the whole point of this repo is building marketable skills, not just working code. |
| **Secrets Manager** (not `.env` in prod) | `.env` + `python-dotenv` locally for fast iteration; Secrets Manager once deployed, since there's no `.env` file inside a Lambda container. |

## CI/CD

Every push runs an automated pipeline via GitHub Actions:

1. **Lint** — `ruff`
2. **Test** — `pytest`, including evals that call the real Claude API
3. **Build** — the Lambda container image, cross-compiled for `arm64` via QEMU (GitHub's runners are `x86_64`, this project's Lambda is `arm64`)
4. **`terraform plan`** — a live, read-only comparison against real AWS state

`terraform apply` stays manual and deliberate — it's the one step that actually changes real infrastructure and costs money, so it's never automated.

**No stored AWS credentials.** The `terraform plan` step authenticates via OIDC: GitHub proves its identity to AWS per-request with a short-lived token, instead of a long-lived access key sitting in a GitHub secret.

`main` is protected — a pull request and a passing CI run are both required before anything can merge.

## Cost

Real AWS money is on the line here, so cost discipline is a deliberate practice, not an afterthought. Steady-state monthly cost, running the current pipeline continuously:

| Item | Cost |
|---|---|
| Lambda (invocations + compute) | ~$0 (well within free tier at this volume) |
| S3, DynamoDB, EventBridge | ~$0 (free tier / negligible at this scale) |
| Secrets Manager | ~$0.40/mo flat (one bundled JSON secret — Secrets Manager bills per secret, not per value inside it, so every API key this project ever needs lives in that one secret) |
| Claude API calls | Low single-digit dollars/month at this call frequency |

**Total: roughly $1–5/month.** The only components of this project that could get genuinely expensive — SageMaker real-time endpoints, an EKS cluster — haven't been built yet, and won't run except in short, deliberately torn-down sessions when they are.

## Running it locally

```bash
uv sync
# .env with ANTHROPIC_API_KEY=... (never committed — see .gitignore)
uv run python main.py
```

Runs the same code path as the deployed Lambda function, using `.env` instead of Secrets Manager for the API key — the code detects which one to use automatically.

### Tests

```bash
uv run pytest
```

Rule-based evals check that the summarizer produces non-empty, non-hedging output across a small set of sample inputs — not just "the API call didn't error."

### Docker

```bash
docker build --provenance=false -t stockwatch .
docker run --env-file .env stockwatch
```

## Status

**Done:** local summarization pipeline (real data + Claude + evals + structured logging); full AWS deployment (S3, Secrets Manager, ECR, IAM, Lambda, EventBridge) via Terraform, verified working end to end in production; a complete CI/CD pipeline (lint, test, Docker build, `terraform plan`) using OIDC-based AWS authentication with no stored credentials, enforced via branch protection on `main`.

**Not yet:** a Kubernetes side-module (self-hosting an open-source LLM on EKS, kept deliberately separate from this main app), an MCP server exposing stockwatch's signals to other tools, and moving beyond a single hardcoded ticker to a real watchlist.

## Known limitations

- `get_stock_data` isn't defensive against malformed `yfinance` responses — a news item missing its `"content"` or `"title"` key will raise a `KeyError`. `yfinance` is an unofficial API wrapper (not a supported Yahoo product), and this is a known, deliberately deferred gap.
