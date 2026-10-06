# Trento agent skills

Tool-neutral skills for coding agents that work on Trento repositories. Each skill is a folder
with a `SKILL.md` in the [Agent Skills](https://agentskills.io) format. Claude Code, Codex,
Cursor, Gemini CLI, GitHub Copilot and OpenCode can load it. The skills here hold process only:
how to prove a test change, how to debug from evidence, how to keep a change narrow. Commands,
tools and limits come from the `AGENTS.md` of each repository, and that file wins on conflict.

For the practices behind the skills, read [PRACTICES.md](PRACTICES.md).

## Install

Install for yourself, for every agent you use (the `-g` flag keeps skills out of project directories):

    npx skills add trento-project/agent-skills -g --skill '*' -a claude-code -a codex -a cursor -a gemini-cli -a github-copilot -a opencode

Update later with `npx skills update -g`. Without Node, clone this repository and link
`skills/*` into `~/.claude/skills/` (Claude Code) and `~/.agents/skills/` (Codex, Cursor,
Gemini CLI, Copilot, OpenCode).

## Skills

| Skill | Use it when |
|---|---|
| [proving-test-changes](skills/proving-test-changes/SKILL.md) | You edit, delete or de-mock a test that still passes afterwards. |
| [test-double-boundaries](skills/test-double-boundaries/SKILL.md) | You decide what to fake in a test and what to assert on. |
| [evidence-first-debugging](skills/evidence-first-debugging/SKILL.md) | Failures appear that the diff does not explain. |
| [shipping-narrow-changes](skills/shipping-narrow-changes/SKILL.md) | Work grows past one reviewable pull request, or you prepare a change for review. |
| [supervising-agent-work](skills/supervising-agent-work/SKILL.md) | You plan work for an agent, delegate to subagents, or review what an agent reports as done. |

Templates:

- [templates/AGENTS.md](templates/AGENTS.md): a skeleton for the `AGENTS.md` of a Trento repository.
- [skills/supervising-agent-work/references/plan.md](skills/supervising-agent-work/references/plan.md): a plan skeleton with a Global Constraints header. It installs with the skill.

## Skills that belong to one repository

A skill about one codebase (its stack, its test helpers, its domain) lives in that repository,
not here:

```
<repo>/
  AGENTS.md
  CLAUDE.md                 # contains only: @AGENTS.md
  .agents/skills/<name>/SKILL.md
  .claude/skills -> ../.agents/skills
```

Codex, Cursor, Gemini CLI, Copilot and OpenCode read `.agents/skills/`. Claude Code reads
`.claude/skills/`, so the symlink points it at the same folder. Name the skill from the
`AGENTS.md` of the repository, so that each agent knows that it exists.

## Admission test

A skill goes in this repository only if all of these are true:

1. It holds in web (Elixir and React), wanda (Elixir) and agent (Go). If not, it is a skill of
   one repository.
2. Its body names no stack tool. Stack examples go in `references/<stack>.md`.
3. It tells the reader that the `AGENTS.md` of the repository wins.
4. Its description says when to use it, not what it does. Start with "Use when".
5. It uses only the six frontmatter fields of the Agent Skills format.
6. `SKILL.md` has at most 300 lines, and each reference file has at most 400.
7. It contains no line numbers, test counts, branch names, customer data, internal URLs or AI
   attribution.

CI checks items 2, 5, 6 and part of 7.

## Contributing

- One skill, or one change to a skill, per pull request.
- Run the two checks from [AGENTS.md](AGENTS.md) before you push.
- If possible, change a skill in the same pull request as the lesson that motivates it.

## License

Apache-2.0. See [LICENSE](LICENSE).
