# Principle 3: Docs scale by folders, not file length

Use folders when they improve navigation, separation of concerns, or future maintenance. Do not split a document just because it crossed an arbitrary section count.

## When to Promote a File to a Folder

- A document has clearly separable subtopics
- Readers would benefit from an index or navigation hub
- Multiple parts are likely to evolve at different rates
- One page is becoming difficult to scan or maintain

## Example Transformation

`gitops.md` becomes too long. Create folder `gitops/` with focused documents:

- `overview.md` - High-level introduction
- `reconciliation.md` - Reconciliation process
- `secrets.md` - Secret management
- `index.md` - Navigation hub

## Do Not Split Too Early

If a page is still easy to read and serves one purpose well, keep it as one file.
