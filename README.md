# GitHub Actions Version Update

A GitHub Action that automatically updates GitHub Actions to their latest versions in your workflow files and creates a pull request with detailed change information.

## About

I created this action to help teams keep their GitHub Actions dependencies up-to-date automatically. Everyone is welcome to use it freely in their projects. If you encounter any issues or bugs, feel free to open an issue and we can solve it together!

## Features

- 🔄 Automatic version detection and updates for all GitHub Actions
- 📊 Detailed PR with version change table
- 🎯 Smart detection - only creates PR when updates are available
- 🏷️ Customizable PR labels and branch naming
- 📝 Professional PR template with review checklist
- ⏭️ Skips commit SHA-based actions automatically
- 🚀 Zero configuration required - works out of the box

## Quick Start

### Minimal Usage

```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.PAT_TOKEN }}

- uses: 525Kiran/525Kiran-actions-version-update@v1
  with:
    github-token: ${{ secrets.PAT_TOKEN }}
```

**Note:** A Personal Access Token (PAT) with `workflow` scope is required. See Setup Guide below.

### Complete Workflow Example

```yaml
name: Update GitHub Actions Versions

on:
  schedule:
    # Run every Monday at 9:00 AM UTC
    - cron: '0 9 * * 1'
  workflow_dispatch: # Allow manual trigger

jobs:
  update-actions:
    name: Update GitHub Actions
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.PAT_TOKEN }}  # Required: PAT with 'workflow' scope
      
      - name: Update GitHub Actions versions
        uses: 525Kiran/525Kiran-actions-version-update@v1
        with:
          github-token: ${{ secrets.PAT_TOKEN }}  # Required: PAT with 'workflow' scope
```

### Custom Configuration

```yaml
- uses: 525Kiran/525Kiran-actions-version-update@v1
  with:
    github-token: ${{ secrets.PAT_TOKEN }}
    git-user-name: 'dependency-bot'
    git-user-email: 'bot@example.com'
    pr-title: 'chore: update github actions to latest versions'
    pr-labels: 'dependencies,automated,github-actions'
    branch-prefix: 'deps/update-actions'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github-token` | GitHub token with `workflow` scope (use PAT) | **Yes** | `${{ github.token }}` |
| `git-user-name` | Git user name for commits | No | `github-actions[bot]` |
| `git-user-email` | Git user email for commits | No | `github-actions[bot]@users.noreply.github.com` |
| `pr-title` | Title for the pull request | No | `chore: update github actions versions` |
| `pr-body` | Body content for the pull request | No | Professional template with table |
| `pr-labels` | Comma-separated labels to add to PR | No | `automated-pr,dependencies` |
| `branch-prefix` | Prefix for the branch name | No | `chore/update-github-actions` |

## Outputs

| Output | Description |
|--------|-------------|
| `updates-made` | Whether any updates were made (true/false) |
| `pr-number` | Pull request number if created |
| `pr-url` | Pull request URL if created |

## Setup Guide

### Basic Setup

**Important:** This action requires a Personal Access Token (PAT) with `workflow` scope because the default `GITHUB_TOKEN` cannot modify workflow files.

1. **Create a Personal Access Token**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a name like "Actions Version Update"
   - Select scopes: `repo` and `workflow`
   - Click "Generate token" and copy it

2. **Add PAT to Repository Secrets**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `PAT_TOKEN`
   - Value: Paste your PAT
   - Click "Add secret"

3. **Create Workflow File**
   - Create `.github/workflows/update-actions.yml` in your repository
   - Copy the complete workflow example above
   - Commit and push the workflow file

4. **Run the Action**
   - The action will run on schedule or can be triggered manually via workflow_dispatch

### Recommended Schedule

```yaml
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM UTC
    # or
    - cron: '0 0 1 * *'  # First day of every month
```

### Required Permissions

The workflow needs these permissions to create PRs:

```yaml
permissions:
  contents: write        # To push branch
  pull-requests: write   # To create PR
```

## How It Works

1. Scans all workflow files in `.github/workflows/`
2. Extracts GitHub Actions and their current versions
3. Queries GitHub API for latest versions
4. Updates version references in workflow files
5. Creates a new branch with timestamp
6. Commits changes and pushes branch
7. Creates a pull request with detailed version change table
8. Adds specified labels to the PR

## PR Output Example

The action creates a professional PR with:

```markdown
## 🔄 Automated GitHub Actions Version Update

This pull request updates GitHub Actions dependencies to their latest available versions.

### 📊 Updated Actions

| Action | Previous Version | Updated Version |
|--------|------------------|-----------------|
| actions/checkout | v3 | v4.2.0 |
| actions/setup-node | v3.8.1 | v4.0.1 |
| peter-evans/create-pull-request | v5.0.2 | v6.1.0 |

### 🔍 Review Checklist

- [ ] Review the version changes and release notes for breaking changes
- [ ] Verify all workflows execute successfully with updated versions
- [ ] Confirm no deprecated features are being used
- [ ] Check for any new required inputs or configuration changes
```

## Troubleshooting

### Error: "refusing to allow a GitHub App to create or update workflow"
This is the most common error. The default `GITHUB_TOKEN` cannot modify workflow files.

**Solution:** Use a Personal Access Token (PAT) with `workflow` scope:
```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.PAT_TOKEN }}

- uses: 525Kiran/525Kiran-actions-version-update@v1
  with:
    github-token: ${{ secrets.PAT_TOKEN }}
```

### Action doesn't create PR
- Verify all actions are not already up-to-date
- Check workflow has required permissions
- Ensure PAT has `repo` and `workflow` scopes
- Verify Actions are enabled in repository settings

### API rate limiting
- PAT tokens have higher rate limits than `GITHUB_TOKEN`
- If you hit rate limits, consider running less frequently

### Permission denied errors
- Ensure you're using a PAT with `workflow` scope (not `GITHUB_TOKEN`)
- Add workflow permissions:
  ```yaml
  permissions:
    contents: write
    pull-requests: write
  ```
- Verify PAT has `repo` and `workflow` scopes enabled

### Updates not detected
- Ensure workflow files are in `.github/workflows/` directory
- Check files have `.yml` or `.yaml` extension
- Verify actions use version tags (not commit SHAs)

### Branch already exists error
- The action uses timestamps in branch names to avoid conflicts
- If error persists, manually delete old branches or change `branch-prefix`

## Advanced Usage

### Custom PR Body Template

You can customize the PR body with placeholders:

```yaml
- uses: 525Kiran/525Kiran-actions-version-update@v1
  with:
    pr-body: |
      ## Custom Update Report
      
      {UPDATES_TABLE}
      
      Generated at: {TIMESTAMP}
      
      Please review carefully!
```

Available placeholders:
- `{UPDATES_TABLE}` - Replaced with version change table
- `{TIMESTAMP}` - Replaced with current UTC timestamp

### Integration with Auto-merge

Combine with auto-merge for fully automated updates:

```yaml
- name: Enable auto-merge
  if: steps.update.outputs.pr-number != ''
  run: gh pr merge ${{ steps.update.outputs.pr-number }} --auto --squash
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Notification on Updates

Send notifications when updates are available:

```yaml
- name: Notify on updates
  if: steps.update.outputs.updates-made == 'true'
  uses: actions/github-script@v7
  with:
    script: |
      console.log('PR created: ${{ steps.update.outputs.pr-url }}')
      // Add your notification logic here
```

## Contributing & Support

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/525Kiran/525Kiran-actions-version-update/issues).

If you find this action helpful, give it a ⭐️ on GitHub!

## License

This project is open source and available for everyone to use freely.