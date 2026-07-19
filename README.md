# BaryoDev org automation

Shared GitHub Actions for every BaryoDev repo.

## Announce a release

`.github/workflows/announce.yml` is a **reusable workflow** that posts a release to this org's
**Announcements** discussions. Call it from any repo's publish workflow so shipping anything —
npm, NuGet, a Docker image — announces itself. It's idempotent: the same title is posted once.

**Requirement:** add an `ANNOUNCE_TOKEN` secret to the calling repo (or org-wide) — a fine-grained
PAT with **Discussions: read and write** on `BaryoDev/.github`.

### npm (after publish, on a Release)

```yaml
jobs:
  # ... your publish job ...
  announce:
    needs: publish
    uses: BaryoDev/.github/.github/workflows/announce.yml@main
    with:
      package: "@baryodev/pwa-kit"
      version: ${{ github.event.release.tag_name || github.ref_name }}
      notes: ${{ github.event.release.body }}
      install: "npm i @baryodev/pwa-kit"
    secrets:
      ANNOUNCE_TOKEN: ${{ secrets.ANNOUNCE_TOKEN }}
```

### NuGet

```yaml
  announce:
    needs: pack-and-push
    uses: BaryoDev/.github/.github/workflows/announce.yml@main
    with:
      package: "BarakoCMS.<Module>"
      version: ${{ github.event.release.tag_name || inputs.version }}
      notes: ${{ github.event.release.body }}
      install: "dotnet add package BarakoCMS.<Module> --version <version>"
    secrets:
      ANNOUNCE_TOKEN: ${{ secrets.ANNOUNCE_TOKEN }}
```

### Docker

```yaml
  announce:
    needs: build-and-push
    uses: BaryoDev/.github/.github/workflows/announce.yml@main
    with:
      package: "barako-cms (docker)"
      version: ${{ github.event.release.tag_name || github.ref_name }}
      notes: ${{ github.event.release.body }}
      install: "docker pull arnelirobles/barako-cms:<tag>"
    secrets:
      ANNOUNCE_TOKEN: ${{ secrets.ANNOUNCE_TOKEN }}
```

### Inputs

| Input     | Required | Notes                                                        |
| --------- | -------- | ------------------------------------------------------------ |
| `package` | yes      | Display name of what shipped.                                |
| `version` | yes      | Version/tag; a leading `v` is trimmed.                       |
| `notes`   | no       | Release notes markdown; falls back to a one-liner.           |
| `install` | no       | Install/pull command, shown in a code block.                 |
