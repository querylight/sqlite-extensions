#!/bin/bash
set -euo pipefail

MANIFEST="manifest.json"
CHANGED=false

update_extension() {
  local id="$1"
  local repo="$2"
  local tag_prefix="$3"

  local current_ver
  current_ver=$(jq -r --arg id "$id" '.extensions[] | select(.id == $id) | .version' "$MANIFEST")

  local latest_tag
  latest_tag=$(gh api "repos/$repo/releases/latest" --jq '.tag_name')
  local latest_ver="${latest_tag#"$tag_prefix"}"

  if [ "$current_ver" = "$latest_ver" ]; then
    echo "$id: up to date ($current_ver)"
    return
  fi

  echo "$id: $current_ver -> $latest_ver"

  # Get platform-specific info from current manifest to build new URLs
  local platforms
  platforms=$(jq -r --arg id "$id" '.extensions[] | select(.id == $id) | .platforms | keys[]' "$MANIFEST")

  for platform in $platforms; do
    local old_url new_url sha256
    old_url=$(jq -r --arg id "$id" --arg p "$platform" \
      '.extensions[] | select(.id == $id) | .platforms[$p].url' "$MANIFEST")

    # Replace version in URL
    new_url="${old_url//$current_ver/$latest_ver}"

    # Compute sha256 of archive
    echo "  Downloading $platform archive..."
    sha256=$(curl -sL "$new_url" | shasum -a 256 | awk '{print $1}')

    # Also try upstream checksums.txt (sqlite-vec publishes one)
    if [ "$id" = "sqlite-vec" ]; then
      local checksums_url="https://github.com/$repo/releases/download/${tag_prefix}${latest_ver}/checksums.txt"
      local archive_name
      archive_name=$(basename "$new_url")
      local upstream_sha
      upstream_sha=$(curl -sL "$checksums_url" | grep "$archive_name" | awk '{print $2}' || true)
      if [ -n "$upstream_sha" ] && [ "$upstream_sha" != "$sha256" ]; then
        echo "  WARNING: computed sha256 differs from upstream checksums.txt for $archive_name"
        echo "  Computed: $sha256"
        echo "  Upstream: $upstream_sha"
        # Trust upstream
        sha256="$upstream_sha"
      fi
    fi

    # Update manifest
    jq --arg id "$id" --arg p "$platform" --arg url "$new_url" --arg sha "$sha256" \
      '(.extensions[] | select(.id == $id) | .platforms[$p].url) = $url |
       (.extensions[] | select(.id == $id) | .platforms[$p].sha256) = $sha' \
      "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"
  done

  # Update version and timestamp
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq --arg id "$id" --arg ver "$latest_ver" --arg now "$now" \
    '(.extensions[] | select(.id == $id) | .version) = $ver | .updatedAt = $now' \
    "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"

  CHANGED=true
}

# Process each extension from manifest
jq -r '.extensions[] | "\(.id) \(.upstream.repo) \(.upstream.tagPrefix)"' "$MANIFEST" | \
  while read -r id repo prefix; do
    update_extension "$id" "$repo" "$prefix"
  done

if [ "$CHANGED" = true ]; then
  echo "Manifest updated."
else
  echo "No updates found."
fi
