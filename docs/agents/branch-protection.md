# Branch protection and pull request workflow

The `main` branch is **protected**. Direct pushes, force pushes, and deletions are prohibited for everyone, including the repository owner. All changes to `main` must arrive through a **pull request**.

## Rule (enforced server-side)

- **Require a pull request before merging**: `required_pull_request_reviews` with `required_approving_review_count: 0` (solo owner can merge own PRs; no self-review block).
- **Do not allow force pushes**: `allow_force_pushes: false`.
- **Do not allow deletions**: `allow_deletions: false`.
- **Enforce for admins**: `enforce_admins: true` (the owner is also subject to the rule).
- **Delete head branches on merge**: enabled in repository settings.
- **Squash merge**: enabled as the preferred merge method.

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
4. Verify CI checks pass.
5. Merge the pull request (squash merge). The head branch is deleted automatically.
6. Pull the updated `main` locally:
   ```
   git checkout main && git pull
   ```

Never run `git commit` directly on `main`, and never `git push` to `main`. The only acceptable state of `main` is the result of a merged pull request.
