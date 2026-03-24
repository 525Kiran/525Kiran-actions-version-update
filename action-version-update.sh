#!/bin/bash
set -euo pipefail

echo "Checking for GitHub Actions updates..."

# Find all workflow files
WORKFLOW_FILES=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null)

if [ -z "$WORKFLOW_FILES" ]; then
  echo "No workflow files found"
  exit 0
fi

UPDATES_MADE=false
UPDATES_LOG=""

# Function to get latest version tag from GitHub
get_latest_version() {
  local repo=$1
  local current_version=$2
  
  # Try to get latest release
  local latest=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | head -1)
  
  # If no releases, try to get latest tag
  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    latest=$(curl -s "https://api.github.com/repos/${repo}/tags" 2>/dev/null | grep '"name":' | head -1 | sed -E 's/.*"name": "([^"]+)".*/\1/')
  fi
  
  # If still nothing, return current version
  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    echo "$current_version"
  else
    echo "$latest"
  fi
}

# Extract unique actions from all workflow files
echo "Scanning workflow files for actions..."
ACTIONS=$(grep -h "uses:" $WORKFLOW_FILES 2>/dev/null | sed 's/.*uses: //' | sed 's/@.*//' | sort -u | grep -v "^\./" || true)

if [ -z "$ACTIONS" ]; then
  echo "No external actions found"
  exit 0
fi

echo "Found actions to check:"
echo "$ACTIONS"
echo ""

for file in $WORKFLOW_FILES; do
  echo "Processing $file..."
  FILE_UPDATED=false
  
  while IFS= read -r action; do
    # Skip local actions and empty lines
    if [[ -z "$action" ]] || [[ "$action" == ./* ]]; then
      continue
    fi
    
    # Check if this action is used in current file
    if ! grep -q "uses: $action@" "$file"; then
      continue
    fi
    
    # Get current version from file
    current_version=$(grep "uses: $action@" "$file" | head -1 | sed "s/.*@//" | awk '{print $1}')
    
    # Skip if it's a commit SHA (40 characters)
    if [ ${#current_version} -eq 40 ]; then
      echo "  ⏭️  Skipping $action (using commit SHA)"
      continue
    fi
    
    # Special handling for actions with branches
    if [[ "$action" == "bridgecrewio/checkov-action" ]]; then
      latest_version="master"
    else
      # Get repository path (owner/repo)
      repo=$(echo "$action" | cut -d'/' -f1-2)
      
      echo "  🔍 Checking $action (current: $current_version)..."
      latest_version=$(get_latest_version "$repo" "$current_version")
    fi
    
    # Compare versions
    if [ "$current_version" != "$latest_version" ] && [ -n "$latest_version" ]; then
      echo "  ⬆️  Updating $action: $current_version → $latest_version"
      
      # Create backup
      cp "$file" "$file.bak"
      
      # Use perl for more reliable replacement (handles special chars better than sed)
      perl -i -pe "s|\Q$action\E\@\Q$current_version\E|$action\@$latest_version|g" "$file"
      
      # Check if file actually changed
      if ! cmp -s "$file" "$file.bak"; then
        FILE_UPDATED=true
        UPDATES_MADE=true
        # Log the update in markdown table format
        UPDATES_LOG="${UPDATES_LOG}|${action}|${current_version}|${latest_version}|\n"
      fi
      
      rm -f "$file.bak"
    else
      echo "  ✅ $action is up to date ($current_version)"
    fi
    
  done <<< "$ACTIONS"
  
  if [ "$FILE_UPDATED" = false ]; then
    echo "  ℹ️  No updates needed for $file"
  fi
  echo ""
done

if [ "$UPDATES_MADE" = true ]; then
  echo "✅ GitHub Actions versions updated"
  echo ""
  echo "Modified files:"
  git diff --name-only
  echo ""
  echo "Summary of changes:"
  git diff --stat
  
  # Save updates log to a file for PR body
  if [ -n "$UPDATES_LOG" ]; then
    echo -e "$UPDATES_LOG" > /tmp/action-updates.log
  fi
else
  echo "ℹ️  All GitHub Actions are already up to date"
fi