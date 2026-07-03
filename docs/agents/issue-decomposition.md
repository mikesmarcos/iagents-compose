# Issue Decomposition Standard

Issues produced by `/to-issues` in this repo follow a principle of **maximum atomicity**: each issue is a recipe, not a design problem.

## Principles

- **One file, one coherent change.** An issue touches one file (or a tightly coupled pair) and adds one logical unit of configuration.
- **No design decisions.** All design is settled in the PRD and ADRs. An issue is pure execution: the implementer follows instructions, they do not choose between alternatives.
- **Single verification.** Each issue has exactly one verification command that confirms the change is correct.
- **Independent.** An issue can be implemented in isolation by a fresh agent with no context beyond the issue body and the PRD it references.
- **Blocked-by explicit.** Dependencies are declared so issues can be picked up in topological order by agents with no shared state.

## Why maximum atomicity

This repo uses subagents backed by modest models (e.g., deepseek-v4-pro, deepseek-v4-flash) for micro-task execution. These models succeed when the task is a deterministic recipe and fail when the task requires synthesizing multiple decisions simultaneously. Atomic issues are the contract that makes this viable: if an agent can read the issue and execute it without making any judgment calls, the model size barely matters.

## Granularity rule

If an issue requires the implementer to decide "which value," "which syntax," or "how to structure this," it is too large. Split it until each step is a single answer with a single verification.

## Template

Every issue includes:
- **Parent**: link to the originating PRD
- **What to build**: the exact change to make, specified as instructions (not as a design brief)
- **Acceptance criteria**: checkbox list with one verification command
- **Blocked by**: explicit issue references, or "None - can start immediately"
