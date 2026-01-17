# git-pm

**Git Push & Merge** – A smart wrapper for the GitHub CLI that validates conventional commits, creates PRs, waits for checks, and auto-merges.

## Why?

Because `git push && gh pr create --fill && gh pr merge --auto --squash` is:
1. Too many commands
2. Uses your branch name as the PR title (gross)
3. Doesn't validate your commit messages
4. Blindly merges without waiting for CI/CD checks

`git-pm` fixes all of this. Write a proper conventional commit, run one command, and let the robot handle the rest.

## Features

- ✅ **Conventional Commits Validation** – Blocks pushes that don't follow the spec
- 🎯 **Proper PR Titles** – Uses your commit message, not your branch name
- ⏱️ **Smart Check Waiting** – Polls GitHub checks and only merges when they pass
- 🚀 **Configurable Merge Strategy** – Squash, merge, rebase – your choice
- 🛡️ **Fail-Fast** – Aborts immediately if checks fail
- 🔧 **Sane Defaults** – Works out of the box with zero config

## Installation

### Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- A repository with a remote on GitHub

### Install the Script

```bash
# Download to somewhere in your PATH
curl -o ~/.local/bin/git-pm https://raw.githubusercontent.com/claylo/git-pm/main/git-pm
chmod +x ~/.local/bin/git-pm

# Or clone and symlink
git clone https://github.com/claylo/git-pm.git
ln -s "$(pwd)/git-pm/git-pm" ~/.local/bin/git-pm
```

## Usage

### Basic Workflow

```bash
# Write a conventional commit
cat > commit.txt << 'EOF'
feat: add user authentication

Implemented OAuth2 flow with Google and GitHub providers.
Added session management and token refresh logic.
EOF

# Commit it
git commit -F commit.txt

# Push, create PR, wait for checks, and merge
git pm
```

That's it. The script will:
1. Validate your commit follows conventional commits
2. Push your branch
3. Create a PR with title `feat: add user authentication`
4. Wait for all GitHub checks to pass
5. Auto-merge with `--auto --squash` (default)

### Skip Auto-Merge

```bash
GIT_PM_MERGE=false git pm
```

This creates the PR but doesn't merge. Useful when you want manual review.

### Custom Merge Strategy

```bash
# Use merge commits instead of squash
GIT_PM_MERGE="--auto --merge" git pm

# Use rebase
GIT_PM_MERGE="--auto --rebase" git pm

# Just squash, no auto
GIT_PM_MERGE="--squash" git pm
```

### Different Base Branch

```bash
# Merge into 'develop' instead of 'main'
GIT_PM_BASE=develop git pm

# Combine with custom merge strategy
GIT_PM_BASE=alpha GIT_PM_MERGE="--auto --rebase" git pm
```

### Set Defaults in Your Environment

Add to your project's `.envrc` (direnv):

```bash
# Always merge into 'develop' for now
export GIT_PM_BASE=develop

# Always use merge commits
export GIT_PM_MERGE="--auto --merge"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_PM_BASE` | `main` | Target branch for the pull request |
| `GIT_PM_MERGE` | `--auto --squash` | Flags passed to `gh pr merge`. Set to `false` to skip auto-merge |
| `GIT_PM_MAX_WAIT` | `300` | Seconds to wait for checks to pass. (Default: 5 minutes) |
| `GIT_PM_INTERVAL` | `5` | Polling interval for checking PR checks |

### Conventional Commits

The script validates that your commit message follows the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Valid types:**
- `feat` – New feature
- `fix` – Bug fix
- `docs` – Documentation changes
- `style` – Code style changes (formatting, etc.)
- `refactor` – Code refactoring
- `perf` – Performance improvements
- `test` – Adding or updating tests
- `build` – Build system changes
- `ci` – CI/CD changes
- `chore` – Maintenance tasks
- `revert` – Reverting changes

**Examples:**
```
feat: add dark mode toggle
fix(api): resolve null pointer in user service
docs: update installation instructions
feat!: remove deprecated v1 endpoints
```

The `!` indicates a breaking change.

### Check Polling

When auto-merge is enabled, the script:
- Polls GitHub checks every 5 seconds
- Waits up to 5 minutes (300 seconds) for checks to complete
- Shows live progress: `⋯ Checks: 2 passed, 1 pending (15/300s)`
- Merges immediately if no checks are configured
- Aborts if any check fails
- Times out gracefully with manual merge instructions

## Examples

### Standard Feature

```bash
# commit.txt
feat: implement file upload with progress tracking

Added drag-and-drop support and chunked uploads for large files.
Includes retry logic and upload resume capability.
```

```bash
git commit -F commit.txt
git pm
```

**Output:**
```
✓ PR created: https://github.com/user/repo/pull/42
⏳ Waiting for PR checks to complete...
  ⋯ Checks: 0 passed, 3 pending (5/300s)
  ⋯ Checks: 1 passed, 2 pending (10/300s)
  ⋯ Checks: 2 passed, 1 pending (15/300s)
✓ All checks passed (3/3)
🚀 Merging PR with: gh pr merge --auto --squash
✓ Done!
```

### Bug Fix to Alpha Branch

```bash
# commit.txt
fix(auth): prevent token refresh race condition

Added mutex lock around token refresh to prevent duplicate requests.
```

```bash
git commit -F commit.txt
GIT_PM_BASE=alpha git pm
```

### Breaking Change with Manual Review

```bash
# commit.txt
feat!: migrate to v2 API schema

BREAKING CHANGE: All API endpoints now use the /v2/ prefix.
Clients must update their base URL configuration.
```

```bash
git commit -F commit.txt
GIT_PM_MERGE=false git pm
```

This creates the PR but doesn't auto-merge, allowing for manual review of breaking changes.

## Error Handling

### Invalid Commit Format

```bash
$ git pm
❌ Error: Commit message does not follow conventional commits format

First line: Add new feature

Expected format: <type>[optional scope]: <description>
Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

Examples:
  feat: add new feature
  fix(api): resolve null pointer exception
  docs: update README with installation steps
```

### Failed Checks

```bash
$ git pm
✓ PR created: https://github.com/user/repo/pull/42
⏳ Waiting for PR checks to complete...
  ⋯ Checks: 2 passed, 1 pending (10/300s)
❌ Check(s) failed. Aborting auto-merge.

View details: https://github.com/user/repo/pull/42

[check status output from gh pr checks]
```

### Timeout

```bash
$ git pm
✓ PR created: https://github.com/user/repo/pull/42
⏳ Waiting for PR checks to complete...
  ⋯ Checks: 2 passed, 1 pending (300/300s)
⏱️  Timeout waiting for checks. You can merge manually:

gh pr merge --auto --squash
```

## When NOT to Use This

- **Large teams with complex review processes** – This is optimized for solo devs or small teams with automated checks
- **Repos without CI/CD** – The smart waiting is overkill if you have no checks
- **When you need multi-commit PRs** – This assumes one commit = one PR
- **Complex PR templates** – The script uses minimal PR metadata

For those cases, just use `gh pr create` directly.

## Troubleshooting

### "command not found: git-pm"

Make sure the script is:
1. In a directory that's in your `$PATH`
2. Executable (`chmod +x git-pm`)
3. Named exactly `git-pm` (no `.sh` extension)

### "gh: command not found"

Install the [GitHub CLI](https://cli.github.com/):
```bash
# macOS
brew install gh

# Linux
sudo apt install gh  # Debian/Ubuntu
sudo dnf install gh  # Fedora

# Windows
winget install GitHub.cli
```

Then authenticate:
```bash
gh auth login
```

### Checks Never Complete

If polling times out but checks are still running:
1. Increase `GIT_PM_MAX_WAIT` in the environment
2. Check your CI/CD configuration for hanging jobs
3. Manually merge: `gh pr merge --auto --squash`

## Development

Want to modify the script? Here's the structure:

1. **Validation** – Extracts and validates conventional commit format
2. **Push** – Pushes current branch to remote
3. **PR Creation** – Creates PR with explicit title/body from commit
4. **Check Polling** – Waits for GitHub checks using `gh pr view --json`
5. **Merge** – Auto-merges with configurable strategy

The script is pure Bash with no external dependencies except `gh` and standard Unix tools (`grep`, `sed`, `head`, `tail`).

## Contributing

PRs welcome! Please:
1. Follow conventional commits (meta!)
2. Test on both macOS and Linux
3. Keep it dependency-free (except `gh`)
4. Add examples to this README for new features

## License

MIT © 2026 Clay Loveless

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI](https://cli.github.com/)
- [Cocogitto](https://github.com/cocogitto/cocogitto) – For conventional commits-based versioning
- [Commitizen](https://github.com/commitizen/cz-cli) – Interactive conventional commit tool

---

**Made with ☕ by a developer tired of typing the same 5 commands.**
