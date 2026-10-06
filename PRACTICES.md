# Working with coding agents on Trento

This guide is for the people who work with agents. The skills in `skills/` are for the agents.

## 1. How we work with agents

Research, plan, implement.

1. **Research.** The agent reads the code and the history, and reports facts with file and
   symbol references.
2. **Plan.** The agent writes a plan with tasks, files and checks. Start from
   [the plan template](skills/supervising-agent-work/references/plan.md). You review the plan. A correction to a plan costs less
   than a correction to code.
3. **Implement.** The agent executes the plan task by task. Each task ends with a check that ran.

You own the plan and the commit. The agent proposes, you decide. See the
`supervising-agent-work` skill.

## 2. Proof over plausibility

Code that looks right is not evidence.

- **Give verification targets.** Each task names the command that must pass and the result that
  you can observe.
- **Prove test changes.** A test that you edit must still fail when the production code breaks.
  Mutate the code, watch the test fail by name, restore. See `proving-test-changes`.
- **Ask for cited reports.** Each claim in a report names the file and the symbol, or the command
  and its output. A claim without a citation is a hypothesis. See `evidence-first-debugging`.
- **Do not accept "PASS" without the output.** A check that did not run is not a pass.

## 3. Context and cost hygiene

These habits hold for every tool.

- **Context compounds.** Each turn sends the whole session again. Clear the context between
  unrelated tasks.
- **Compact with a focus.** When you compact, say what to keep, for example "keep the failing test
  names and the plan state".
- **Prefer command-line tools to MCP servers.** `gh`, `kubectl` and `osc` cost less context than a
  server that loads its tool list in each session. Disable MCP servers that you do not use.
- **Delegate research.** Send broad searches to a subagent on a small model. Only its summary comes
  back.
- **Prefilter logs.** Give the agent the failing lines, not the whole log.
- **Choose the model and the effort for the task.** The prompt cache expires after about five idle
  minutes. A switch of model or session discards it.
- **Plan first, give verification targets, test step by step.** Output-compression plugins can
  help too.

For SUSE tool choice and cost rules, ask internally.

## 4. Writing AGENTS.md and skills

- **Keep `AGENTS.md` short.** Each agent loads it in every session. Aim for under 150 lines.
- **Commands first.** Put the exact commands for setup, checks and tests at the top. Use real
  snippets, not descriptions.
- **Write boundaries in two tiers.** "Ask first" for actions that need a human's go, "Never" for
  actions that are forbidden.
- **Add a rule the second time a mistake happens.** Not the first time.
- **Prefer a lint rule or a hook to a prose rule.** A check that runs does not depend on the agent
  reading it.
- **Update the skill in the same pull request as the code** that changes the lesson.

Use [templates/AGENTS.md](templates/AGENTS.md) as the start. A repository that needs a skill
about its own stack puts it in `.agents/skills/`. See the README.

## 5. Safety

- Do not put secrets or customer data in prompts, plans, skills or any other artifact. This
  includes logs, support files and case material.
- Review every diff before it lands.
- Agents never push to shared branches without being asked.

## 6. Open team decisions

These are not settled. Until the team decides, do not treat either as a rule:

- Whether commits and pull requests mention AI assistance.
- Whether agent plan and spec files get committed.

## 7. Inspiration

| Source | Borrowed pattern |
|---|---|
| [agentsmd/agents.md](https://github.com/agentsmd/agents.md) | `AGENTS.md` spec. Nearest file wins. Symlink old names. |
| [agentskills/agentskills](https://github.com/agentskills/agentskills) | `SKILL.md` standard, progressive disclosure, `skills-ref validate`. |
| [obra/superpowers](https://github.com/obra/superpowers) | Trigger-only descriptions. One tree, many tool manifests. |
| [anthropics/skills](https://github.com/anthropics/skills) | Skill template, `scripts/` and `references/` layouts. |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | Lifecycle commands over skills. |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | `npx skills add`: one copy, symlinked into each agent. |
| [github/spec-kit](https://github.com/github/spec-kit) | Spec, plan, tasks as artifacts. Project constitution. |
| [github/awesome-copilot](https://github.com/github/awesome-copilot) | Layout split by artifact type. `applyTo` globs. |
| [wshobson/agents](https://github.com/wshobson/agents) | One source, per-tool adapters, evals. |
| [intellectronica/ruler](https://github.com/intellectronica/ruler) | One rules source, generated per tool. |
| [humanlayer/advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) | Research, plan, implement. Human reviews the plan. Subagents for context control. |
| [ash-project/usage_rules](https://github.com/ash-project/usage_rules) | Dependency rules synced into `AGENTS.md` between managed markers. |
| [phoenixframework/phoenix](https://github.com/phoenixframework/phoenix) (`mix phx.new`) | Generated `AGENTS.md` for a new project. |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | Single-role subagents with small tool allowlists. |
| [apache/airflow](https://github.com/apache/airflow), [vercel/next.js](https://github.com/vercel/next.js), [temporalio/temporal](https://github.com/temporalio/temporal) | Real `AGENTS.md` files: tiered boundaries, nested files per package. |
| GitHub blog, "How to write a great agents.md" (2,500 repos) | Six core areas. Commands first. Boundaries. |
| [Anthropic, Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Verification first. Prune instructions like code. |
| HumanLayer, "Writing a good CLAUDE.md" | Short file. Never use the LLM as a linter. |
| Vercel, "AGENTS.md outperforms skills in our agent evals" | Always-needed knowledge in `AGENTS.md`. Explicit skill pointers. |

The [superpowers](https://github.com/obra/superpowers) skills (brainstorming, plans, test-driven
development) are a good optional install next to these. This repository does not copy them.
