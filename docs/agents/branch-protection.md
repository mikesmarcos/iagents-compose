# Branch protection and pull request workflow

The `main` branch is **protected**. Direct pushes, force pushes, and deletions are prohibited for everyone, including the repository owner. All changes to `main` must arrive through a **pull request**.

## Rules (enforced server-side)

Two layers protect `main`: classic **branch protection** and a repository **ruleset**.

### Branch protection rule (classic)

Visible in **Settings → Branches → Branch protection rules**.

- **Require a pull request before merging**: `required_approving_review_count: 1` — every PR needs exactly one approving review.
- **Require review from code owners**: `require_code_owner_reviews: true` — the approval must come from a CODEOWNERS-listed owner. `.github/CODEOWNERS` designates `@mikesmarcos` as owner of every path, so only `mikesmarcos` can approve.
- **Dismiss stale pull request approvals when new commits are pushed**: `dismiss_stale_reviews: true` — pushing to an open PR invalidates prior approvals.
- **Require approval of the most recent reviewable push**: `require_last_push_approval: true` — `mikesmarcos` must approve the latest push, not just an older commit.
- **Do not allow bypassing the above settings**: `enforce_admins: true` — `mikesmarcos` is also bound by the rule, even as repo owner, and cannot self-approve (GitHub blocks self-approval).
- **Require linear history**: `required_linear_history: true` — no merge commits; squash/rebase only.
- **Require status checks to pass before merging**: `strict: true` with `pr-only-policy` context.
- **Do not allow force pushes**: `allow_force_pushes: false`.
- **Do not allow deletions**: `allow_deletions: false`.
- **Require conversation resolution**: `required_conversation_resolution: true`.

### Repository ruleset (Settings → Rules → Rulesets)

A `main-branch-protection` ruleset reinforces the structural rules:

- **Deletion**: blocks deletion of `main`.
- **Non fast-forward**: blocks force pushes to `main`.
- **Required linear history**: enforces linear history.

> The ruleset `pull_request` rule is not currently used because that rule type requires an organization repository; `mikesmarcos/iagents-compose` is a user account. The classic branch-protection layer already enforces the code-owner approval requirement and takes precedence over the ruleset.

### Repository settings

- **Delete head branches on merge**: enabled.
- **Squash merge**: enabled as the preferred merge method.

## Approved reviewers and PR sources

Only **`@mikesmarcos`** can approve PRs (he owns every path in `.github/CODEOWNERS`). GitHub does not allow authors to self-approve their own PRs, so:

- PRs opened by `mikeiagents` must be approved by `mikesmarcos` before merge.
- PRs opened by `mikesmarcos` cannot be merged by himself; they would need an approving review from another code owner, which currently does not exist. In practice `mikesmarcos` does not open implementation PRs.

## Limitation: restricting who can open PRs

For a user-owned public repository, GitHub does not offer a setting to restrict who can *open* pull requests — anyone can fork and open a PR. However:

- Only `mikesmarcos` and `mikeiagents` have push access as collaborators, so only they can push feature branches to the repo directly. Outside contributors must fork.
- Branch protection blocks *all* PRs from merging without `mikesmarcos` approval, regardless of author.
- To exclude untrusted PRs entirely, the repository would need to be moved to an organization (where PR creation can be restricted to collaborators) or made private.

## Defense in depth

A GitHub Action (`.github/workflows/main-branch-protection.yml`) runs on every pull request targeting `main` and passes as a visible status check documenting the PR-only policy. Direct pushes to `main` are already blocked server-side by branch protection rules, so the workflow does not need to (and must not) run on pushes to `main`, because PR merges also fire push events and would otherwise be incorrectly rejected.

## Required workflow per change

1. Create a feature branch from `main`:
   ```
   git checkout -b feat/<short-description>
   ```
2. Make commits on the feature branch.
3. Push the branch and open a pull request:
   ```
   git push -u origin feat/<short-description>
   gh pr create --base main
   ```
4. Verify CI checks pass (`pr-only-policy` must be green).
5. **`mikesmarcos` approves the pull request.** The PR cannot be merged without his approval (`require_code_owner_reviews`, `required_approving_review_count: 1`, `enforce_admins: true`).
6. Merge the pull request (squash merge). The head branch is deleted automatically.
7. Pull the updated `main` locally:
   ```
   git checkout main && git pull
   ```

Never run `git commit` directly on `main`, and never `git push` to `main`. The only acceptable state of `main` is the result of a merged pull request approved by `@mikesmarcos`.
