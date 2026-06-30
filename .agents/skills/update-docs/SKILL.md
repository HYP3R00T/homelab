---
name: update-docs
description: "Update documentation in this repository using Markdown. Use when asked to add, revise, or verify docs content in docs/, README.md, or skill/reference files under .agents/skills; includes edit workflow, clarity standards, build validation, and change summary expectations."
argument-hint: "Describe what docs to update and what should change."
---

# Update Docs

## When To Use

- User asks to update docs pages, navigation, examples, or setup instructions.
- User asks to fix docs errors, broken references, or stale configuration notes.
- User asks to align docs with code/tooling changes in this repository.
- User asks to add documentation for a new feature, service, workflow, or repository area.

## Repository Context

- Docs source is in `docs/`.
- Site configuration is in `zensical.toml` (this project uses Zensical/MkDocs Material).
- Generated site output is in `site/` and should not be manually edited.
- Repository guidance may also live in `README.md` and `.agents/skills/`.
- This repository is a homelab GitOps repo organized mainly around `apps/`, `infrastructure/`, `monitoring/`, and `clusters/`.

## Procedure

1. Identify the audience, purpose, and scope of the requested document update.
2. Read relevant files first: the page being edited, `zensical.toml` for navigation context, and any related pages.
3. Apply the documentation principles from the local skill references listed below, prioritizing clarity and reader understanding over rigid templates.
4. Make minimal, targeted edits that improve accuracy, readability, and structure without adding unrelated refactors.
5. If a new page is added or a page is renamed, update `nav` in `zensical.toml`.
6. Validate docs render successfully when practical:
    - `uv sync` (if dependencies are missing)
    - `uv run zensical build --clean`
7. Report exactly what changed and where, including any commands run and notable output.

## Documentation Principles Reference

- [Principle 0: Write for the reader](./references/principle-0-reader-first.md)
- [Principle 1: Docs describe what exists](./references/principle-1-no-fiction.md)
- [Principle 2: One document, one purpose](./references/principle-2-single-responsibility.md)
- [Principle 3: Docs scale by folders](./references/principle-3-scale-by-folders.md)
- [Principle 4: Link to code properly](./references/principle-4-link-to-code.md)
- [Principle 5: Format and consistency](./references/principle-5-format-style.md)
- [Principle 6: Structure should fit the repository](./references/principle-6-structure-uniformity.md)

## Content Rules

- Keep examples short, accurate, and executable where possible.
- Prefer plain language and explicit commands over abstract guidance.
- Use formatting to improve comprehension, not to decorate.
- Prefer keyboard-friendly punctuation for consistency; use unusual symbols sparingly.
- Do not add unrelated refactors while updating docs.
- Do not include secrets, tokens, or local-only sensitive values in docs.

## Quality Checklist

- Markdown formatting is consistent and readable.
- Commands in docs match current tooling when commands are included.
- Links and references point to existing files or valid URLs.
- New pages are registered in `zensical.toml` nav.
- Docs build command completes successfully when validation is run.

## Response Expectations

- Summarize changes by file and purpose.
- Mention validation commands executed.
- If validation was not run, state that clearly and explain why.
