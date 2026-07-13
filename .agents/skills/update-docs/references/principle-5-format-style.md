# Principle 5: Format, style, and consistency

Avoid patterns that undermine readability or signal poor authorship. These standards keep documentation clean and professional.

## Punctuation and Em Dashes

Use punctuation intentionally. Em dashes are allowed, but use them sparingly and consistently within a document.

Prefer keyboard characters when they communicate just as clearly.

**DON'T:**

- Overuse em dashes in every paragraph
- Mix many punctuation styles for the same purpose

**DO:**

- "Configuration (provided in the setup file) is required"
- "Configuration - provided in the setup file - is required"
- "Configuration—provided in the setup file—is required" (when your team prefers em dashes and uses them consistently)

## Directional Arrows and Symbols

Symbols are allowed in moderation. For most technical docs, prefer plain prose, lists, and keyboard-available characters.

**DON'T:**

- Decorate steps with many special symbols
- Use symbol-heavy notation when plain text is clearer

**DO:**

- Use numbered lists for sequences
- Use simple punctuation and plain labels

## ASCII Art and Box Diagrams

Do not use decorative ASCII diagrams that add noise. Simple structural code blocks are allowed when they help explain folders, trees, or short layouts.

**DON'T:**

- Box drawings or ASCII flow diagrams

**DO:**

- Prose descriptions and numbered lists
- Short repository trees or layout blocks when structure is the point

## Mermaid Diagram Direction

Use a top-to-bottom layout for Mermaid flowcharts so labels and relationships
remain readable in the documentation content column.

**DO:**

```text
flowchart TB
```

**DON'T:**

```text
flowchart LR
```

Use another direction only when the diagram has a specific layout requirement
that remains readable at the rendered page width.

## Emoji Usage

Professional documents should use little to no emoji. If used, keep emoji rare and never rely on them for meaning.

**DON'T:**

```text
✅ Done
❌ Not done
```

**DO:**

```text
Done
Not done
```

## Unicode Escape Sequences in Prose

Escape sequences appear as literal text in many systems and are not accessible.

**DON'T:**

- Use "\u274c" or "\u2705" in documentation text

**DO:**

- Use plain text labels: "(DO)", "(DON'T)", "(GOOD)", "(AVOID)"

## Code Block Language Specifiers

Use language tags for executable or syntax-highlightable code blocks. Plain `text` blocks are acceptable for trees, output snippets, or simple structural examples.

**DON'T:**

```text
kubectl apply -f deployment.yaml
```

**DO:**

```shell
kubectl apply -f deployment.yaml
```
