# Model providers and execution modes

This repo uses two model providers. Understanding which to use and when is critical for both the orchestrator and spawned subagents. All 22 subagent TOMLs in `.codex/agents/` set `model_provider = "fcc"` explicitly.

## Provider overview

| Provider | Serves | Auth mechanism | How to activate |
|----------|--------|----------------|-----------------|
| `openai` (built-in) | OpenAI models only (gpt-5.4-mini, gpt-5.4, gpt-5.5) | ChatGPT sign-in (`~/.codex/auth.json`) | Default when running `codex` without overrides |
| `fcc` (custom proxy) | **Both** opencode_go models AND OpenAI models | `FCC_CODEX_API_KEY` env var | `fcc-codex` wrapper, or `-c model_provider=fcc` |

The `fcc` provider proxies through the Free Claude Code local server (`fcc-server` at `127.0.0.1:8082`). It is a **universal proxy** — it forwards opencode_go model requests to the opencode_go backend and OpenAI model requests to the OpenAI API. All 7 models used by the subagents work through this single provider.

## Standardized approach: always use fcc

**All 22 subagent TOMLs set `model_provider = "fcc"`.** This guarantees every agent — opencode_go or OpenAI — routes through the fcc proxy regardless of the parent session's provider. The fcc provider is also defined in `~/.codex/config.toml` so it is available even when not running via the `fcc-codex` wrapper.

### Running the orchestrator (interactive)

**Always start the orchestrator via `fcc-codex`** (not plain `codex`). This sets the session's provider to `fcc`, which serves all 22 subagent models. Subagents inherit the parent session's provider, so all dev and test executors work automatically.

```bash
fcc-codex   # interactive session, provider=fcc, all 7 models available
```

The `fcc-server` must be running at `127.0.0.1:8082`. Start it in a separate terminal:

```bash
fcc-server
```

### Non-interactive / scripted execution

For non-interactive use (CI, test scripts, one-off prompts), call `codex exec` directly with the fcc provider config **after** the `exec` subcommand:

```bash
codex exec -c model_provider=fcc -m opencode_go/minimax-m3 "your prompt"
```

Since the fcc provider is defined in `~/.codex/config.toml`, the single `-c model_provider=fcc` flag is sufficient — no need to repeat the full provider definition.

> **Known issue — `fcc-codex exec`:** the `fcc-codex` launcher injects `-c model_provider=fcc` *before* the `exec` subcommand, but `codex exec` (clap) ignores global options positioned before the subcommand name. The provider silently falls back to `openai`, which cannot serve opencode_go models. **Workaround:** use `codex exec -c model_provider=fcc ...` directly for non-interactive use. Interactive `fcc-codex` sessions (no `exec`) are unaffected.

## fcc provider definition

Defined in `~/.codex/config.toml` (global config, not part of this repo):

```toml
[model_providers.fcc]
name = "Free Claude Code"
base_url = "http://127.0.0.1:8082/v1"
env_key = "FCC_CODEX_API_KEY"
wire_api = "responses"
```

## Validation test script

`scripts/test-subagent-models.sh` validates that every model used by the subagents is reachable through its configured provider. Run it after any change to agent TOMLs or provider config:

```bash
bash scripts/test-subagent-models.sh
```

The script sends a trivial prompt to each model and checks for a `TESTOK` response. It tests:

- 4 opencode_go models via fcc (medium effort)
- 3 OpenAI models via fcc (medium effort)
- 3 OpenAI models via openai (medium effort, fallback check)
- 2 high-effort spot checks via fcc

**Requirements:** `codex` CLI on PATH, `fcc-server` running at `127.0.0.1:8082`, `FCC_CODEX_API_KEY` set, `~/.codex/config.toml` with the fcc provider section, and `~/.codex/auth.json` for openai-provider tests.

## Validated test matrix

All tests run on 2026-07-04 via `scripts/test-subagent-models.sh`. **Every test passed.**

| # | Model | Provider | Effort | Result |
|---|-------|----------|--------|--------|
| 1 | `opencode_go/deepseek-v4-pro` | fcc | medium | ✅ pass |
| 2 | `opencode_go/deepseek-v4-flash` | fcc | medium | ✅ pass |
| 3 | `opencode_go/minimax-m3` | fcc | medium | ✅ pass |
| 4 | `opencode_go/glm-5.2` | fcc | medium | ✅ pass |
| 5 | `gpt-5.4-mini` | fcc | medium | ✅ pass |
| 6 | `gpt-5.4` | fcc | medium | ✅ pass |
| 7 | `gpt-5.5` | fcc | medium | ✅ pass |
| 8 | `gpt-5.4-mini` | openai | medium | ✅ pass |
| 9 | `gpt-5.4` | openai | medium | ✅ pass |
| 10 | `gpt-5.5` | openai | medium | ✅ pass |
| 11 | `opencode_go/minimax-m3` | fcc | high | ✅ pass |
| 12 | `gpt-5.4` | fcc | high | ✅ pass |

**Key findings:**

1. The fcc proxy is universal — serves all 7 models (4 opencode_go + 3 OpenAI) at both medium and high reasoning effort.
2. OpenAI models work through both `openai` and `fcc` providers. The `fcc` provider is the standardized choice for all subagents.
3. Plain `codex` (provider=openai) only serves OpenAI models; opencode_go models require the fcc provider.
4. The `fcc-codex exec` config-positioning bug only affects non-interactive CLI use. Interactive `fcc-codex` sessions and `codex exec -c model_provider=fcc` both work correctly.

## Model metadata warnings

opencode_go models produce a cosmetic warning: `Model metadata for 'opencode_go/...' not found. Defaulting to fallback metadata.` This does not affect functionality — the model responds correctly. The warning appears because Codex's model catalog only includes OpenAI models; the fcc proxy handles routing regardless.
