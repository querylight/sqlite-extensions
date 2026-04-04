# sqlite-extensions

Curated manifest of trusted SQLite extension releases for [QueryLight](https://querylight.app).

## What this is

A `manifest.json` that maps popular SQLite extensions to their upstream pre-built macOS binaries (arm64 + x86_64). QueryLight fetches this manifest to populate its Extension Gallery.

**No binaries are hosted here.** All downloads point directly to upstream GitHub releases.

## Extensions

| Extension | Upstream | Description |
|-----------|----------|-------------|
| [sqlite-vec](https://github.com/asg017/sqlite-vec) | asg017/sqlite-vec | Vector search, pure C, no deps |
| [sqlean](https://github.com/nalgeon/sqlean) | nalgeon/sqlean | All-in-one toolkit (crypto, text, math, stats, regexp, uuid) |

## Automated updates

A weekly GitHub Actions cron checks upstream repos for new releases and opens a PR to update the manifest. All updates are reviewed before merging.

## Adding an extension

Add an entry to `manifest.json` with:
- `id`: unique identifier
- `upstream.repo`: GitHub `owner/repo`
- `upstream.tagPrefix`: tag prefix to strip for version (e.g. `"v"` or `""`)
- `platforms`: macOS arm64 and x86_64 download URLs, sha256 checksums, and dylib filename
