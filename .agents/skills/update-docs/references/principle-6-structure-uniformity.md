# Principle 6: Documentation structure uniformity

Consistency helps readers navigate confidently, but structure should fit the repository rather than forcing the repository into a universal template.

---

## File Naming

Use lowercase with hyphens only.

**DO:**

- `getting-started.md`
- `alpha-matting.md`
- `environment-variables.md`

**DON'T:**

- `GettingStarted.md`
- `AlphaMatting.md`
- `Environment_Variables.md`

---

## Folder Structure

When a folder contains multiple related documents, consider adding an `index.md` as a navigation hub.

`index.md` should:

- List all documents in the folder with one-line descriptions
- Be the entry point for readers discovering the folder
- Use consistent naming (`index.md`, not `README.md`)

---

## Document Structure

Most documents should:

- Start with a clear `# Title`
- Establish context early
- Use headings that match the reader's task or question
- End before they become bloated

Use only the sections that help the document do its job. Do not force every page into the same outline.

---

## Zensical-Specific Notes

When using Zensical (this project's doc toolchain):

- Navigation is defined in `zensical.toml` under `nav`. Top-level entries become tabs (due to `navigation.tabs` feature).
- After adding or renaming any page, update `nav` in `zensical.toml` or the page will not appear in the site.
- Validate with `uv run zensical build --clean` before committing.
