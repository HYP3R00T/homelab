# Principle 4: Link to code properly

Never duplicate large code blocks. Link to the source instead. Code changes frequently; docs do not.

## Linking to Documentation Files

Use relative paths within the `docs/` folder.

**DO:**

- `[Principle 1: Docs describe what exists](principle-1-no-fiction.md)`
- `[Principle 5: Format and consistency](principle-5-format-style.md)`

**DON'T:**

- Relative paths to code outside docs: `[config](../../pyproject.toml)`
- Broken anchor attempts to non-doc files

## Linking to Code and Non-Documentation Files

Inside repository documentation, prefer repository-relative file paths written as code when referring to files outside `docs/`.

Use full GitHub permalinks only when you explicitly need a clickable external link in published docs.

**DO:**

- `zensical.toml`
- `infrastructure/lab/kustomization.yaml`
- `apps/base/linkding/kustomization.yaml`

**DON'T:**

- Absolute local filesystem paths such as `/home/user/project/...`
- Broken relative links outside the docs tree
- Links without protocol or host: `blob/main/file.py`

## Portable Repository References

Documentation should stay valid if the repository is moved to another machine or cloned into a different directory.

That means:

- do not use absolute local paths
- prefer repository-relative paths in prose
- only use clickable links when they are actually portable in the rendered environment

## Referencing Git History and Decisions

When writing "Thinking" or "Journey" docs, link to specific commit SHAs.

**DO:**

- "In [commit a1b2c3d](https://github.com/HYP3R00T/homelab/commit/a1b2c3d), we changed the cluster layout to simplify navigation"
