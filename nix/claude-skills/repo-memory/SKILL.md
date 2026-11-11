---
name: repo-memory
description: Set up the current project so Claude's project memory/knowledge is stored in the git repo (.claude/memory/ + a lean CLAUDE.md) instead of ~/.claude. Use only when the user explicitly asks to set up in-repo memory for this project (e.g. /repo-memory).
---

# Set up in-repo project memory

Goal: everything Claude learns about this project persists in the repo, because the home directory
(and `~/.claude`) may be ephemeral. Do this only for the current project.

## Steps

1. Find the repo root (`git rev-parse --show-toplevel`; fall back to the cwd if not a git repo).

2. Create `.claude/memory/MEMORY.md` if missing:

   ```markdown
   # Memory index
   ```

3. Add this section to `<root>/CLAUDE.md`. If CLAUDE.md exists, read it first and append the section
   (skip if an equivalent "## Memory" section already exists); otherwise create the file with a
   `# CLAUDE.md` heading followed by the section. Do not put any memory content in CLAUDE.md.

   ```markdown
   ## Memory

   Project memory lives in this repo under `.claude/memory/`, not in `~/.claude/projects/.../memory/`.
   The home directory may be ephemeral, so everything learned about this project must be written here.

   - One fact per file in `.claude/memory/`, with frontmatter (`name`, `description`, `metadata.type`:
     user | feedback | project | reference). Link related notes with `[[name]]`.
   - Add a one-line pointer to each note in `.claude/memory/MEMORY.md` (the index, imported below).
   - Update existing notes rather than duplicating; delete notes that turn out to be wrong.
   - Keep this file lean: no auto-memory content here.

   @.claude/memory/MEMORY.md
   ```

4. Migrate existing auto-memory: look in `~/.claude/projects/<sanitized-cwd>/memory/` (sanitized cwd =
   absolute path with `/` replaced by `-`, e.g. `/work/x` → `-work-x`). Move any note files into
   `.claude/memory/` and merge their index lines into `.claude/memory/MEMORY.md` (skip duplicates).
   Tell the user what was migrated.

5. Save a feedback note `.claude/memory/feedback-memory-in-repo.md` recording that the user wants all
   project memory kept in the repo (Why: home dir is ephemeral; How to apply: write notes here, never
   to ~/.claude), and add it to the index.

6. If `.gitignore` would ignore `.claude/` or `CLAUDE.md`, tell the user. Do not commit unless asked.

7. Report the files created/changed. From now on in this session, write memory to `.claude/memory/`.
