# Global Rules

These rules apply to every AI agent session regardless of project.

## General

- **Always read the actual source code.** If the service is not cloned locally, clone it to ~/sources or use the sourcegraph-cli skill to find it.
- Never guess, always include data to support your claims
- Include links for things that you research
- Delegate knowledge exploration to subagents to preserve context
- If stuck after 2 failed attempts, stop and summarize findings for the user

## Communication

- Be direct and concise; skip preamble
- Present options with trade-offs and a recommendation
- Ask one clarifying question at a time, not a wall of questions

## Security

- Never commit secrets, API keys, tokens, or credentials
- Validate and sanitize all external input
- Use environment variables, OS keychain, or a secret manager for sensitive values
- Before any destructive or broad-blast-radius action (rm, force-push, branch/worktree deletion, editing configs outside the current repo, home-directory changes) back up affected state and get explicit confirmation first
- Treat vague or broad requests ("clean up X", "organize Y", "remove old Z") as requiring a scoped survey and categorized plan presented for confirmation -- never a blind sweep

## Knowledge Management

At the start of every session, list the directory tree of `~/.ai/knowledge/` to see what topics/knowledge already exist.

- Use that tree as a map: each subfolder is a topic with a `meta.yaml` (name/description/resources) and one or more freely-named `.md` files of knowledge. Read the relevant `.md` file(s) when working on something related to a listed topic.
- Folder names aren't always obvious (e.g. "sim" for SIE) -- check `~/.ai/knowledge/acronyms.yaml` to resolve an unfamiliar acronym/keyword to its topic before assuming there's no local knowledge on it.
- Don't read every file indiscriminately -- only load what's relevant to the current task.
- When new information is discovered, check the tree first to decide where it belongs -- an existing topic folder, or a new one -- before saving. Prefer adding to an existing `.md` file over creating a new one unless the topic is genuinely new. Add new acronyms/keywords to `acronyms.yaml` as they come up.
- The global `~/.ai/knowledge/meta.yaml` holds personal identity; there's no separate global notes file until there's global (non-topic-specific) knowledge worth capturing.

## Design Documents

Write design docs and implementation plans to `~/.ai/designs/<repo-name>/<design-name>.md`, not inside the project repo itself. This keeps them out of the repo's history/PRs/gitignore entirely.

- Mirror `~/.ai/knowledge/`'s structure: one subfolder per repo, freely-named `.md` files inside.
- Reference the repo and relevant source files by path within the doc so it stays traceable even though it lives outside the repo.
- If the user explicitly asks for the doc to live in the repo (e.g. for team visibility in a PR), that overrides this default.

## Coding

### New Feature Development

- Must follow test driven development
- Step 1: create test cases and example output
- Step 2: get approval of test cases and output
- Step 3: create implementation plan
- Step 4: get approval for implementation plan
- Step 5: implement the plan
- Step 6: check that all test cases pass and output matches expected
- Step 7: spin up a new agent with fresh context to review your work
- Step 8: fix anything that needs fixing
- Step 9: check that all test cases pass and output matches expected
- Step 10: give a high level summary of the architecture of the solution

### Code Quality

- Write clear, self-documenting code; prefer readability over cleverness
- Handle errors explicitly; never swallow errors silently
- Remove dead code rather than commenting it out
- Prefer descriptive variable names

### Documentation

- Don't create documentation files (README, CHANGELOG, etc.) unless explicitly asked
- Always prefer short concise documentation
- Every new code file should include documentation at the top about it's purpose.
- Prefer inline code comments for non-obvious logic over separate docs
- Update existing docs when changing behavior they describe
- Write all technical English (docs, comments, commit messages, PR descriptions) per **ASD-STE100 (Simplified Technical English)**: short sentences, active voice, imperative mood for procedures, approved/consistent vocabulary (one word per meaning), no jargon or idioms, one instruction per sentence

### Testing

- Write tests for new functionality
- Ensure existing tests pass before committing
- Prefer tests that exercise real behavior over excessive mocking
- Test edge cases and error paths, not just the happy path

### Git & Commits

- Always work in a git worktree whose directory name starts with `ai-` (for example `ai-fix-login`). Create one before you change any file. Do not edit files in the main checkout or in a worktree that does not start with `ai-`. If you are already in an `ai-` worktree, keep using it.
- Name the git branch with only the meaningful part of the worktree name. Remove the `ai-` prefix (for example, worktree `ai-fix-login` uses branch `fix-login`). Do not add an `ai/` or `ai-` prefix to the branch name.
- Use conventional commit messages: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `ci`
- Keep commits atomic -- one logical change per commit
- Write commit messages explaining **why**, not **what**
- Always run tests before committing when a test suite exists
- Keep PR descriptions concise: problem, fix, testing -- skip narrating the investigation process, dead ends, or exploratory back-and-forth
- **NEVER push to remote without explicit user approval**
- Never run destructive git operations (force push, hard reset, history rewrite, deleting unmerged branches) without explicit user approval

### Nix

- Use orbstack for nix development
