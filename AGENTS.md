# trento-project/agent-skills

Generic, tool-neutral skills for coding agents that work on Trento repositories.

## Commands

```bash
tests/run.sh                              # self-test of the check script
scripts/check-skills.sh skills --neutral  # validate every skill
```

## Rules for skills in this repo

- Frontmatter: only name, description, license, compatibility, metadata, allowed-tools.
  `name` equals the directory name. `description` starts with "Use when" and lists
  trigger conditions only.
- `SKILL.md` at most 300 lines. `references/*.md` at most 400 lines.
- The body names no language, test runner, command or threshold. Stack examples go in
  `references/<stack>.md`.
- Each skill says that the repository's own AGENTS.md wins on commands, tools and limits.
- Admission test: the skill must hold in web (Elixir/React), wanda (Elixir) and agent (Go).
  If it does not, it belongs in that repository.
- No line numbers, test counts, branch names, customer data, internal URLs or AI attribution.
