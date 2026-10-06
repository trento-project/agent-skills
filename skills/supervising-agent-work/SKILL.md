---
name: supervising-agent-work
description: Use when planning multi-step work for an agent, delegating tasks to subagents, reviewing work an agent reports as done, or when a session's context is filling up with search and log output.
---

# Supervising agent work

The repository's AGENTS.md wins on commands, branch rules and the actions that need the
human's go.

## 1. Research, plan, implement

Split the work in three phases, and keep them apart.

1. **Research.** Read the code, the docs and the history. The output is facts with file and
   symbol references, not changes.
2. **Plan.** Write the tasks, the files, the checks and the order. Start from
   `references/plan.md`. The human reviews the plan, not every line of the result. One correction
   to a plan costs less than ten corrections to code.
3. **Implement.** Execute the plan task by task. Each task ends with a check that ran.

If the research changes the plan, update the plan file. Do not keep the change only in the chat.

## 2. The Global Constraints header

At the top of every plan, list once what the agent must never do in this work. Each task
inherits the list. Typical items:

- Commits, pushes, pull requests: allowed, or "the human does them".
- Worktrees and branches: which ones, or none.
- Behaviour that must not change: error messages, outputs, cache keys, public interfaces.
- Tools that are blocked or broken in this environment, with the working invocation.
- Version pins and limits copied from the spec.

A constraint that is only in the chat is gone after the next compaction. A constraint in the
header survives it, and each subagent that reads the task reads the header too.

## 3. No "PASS" without the command and its output

A report of "tests pass" is a claim. The evidence is the command and the output that it printed.

- Ask for both, and read the output. A summary line such as "12 passed, 0 failed" counts. A
  sentence such as "all checks are green" does not.
- A check that did not run is not a pass. "Skipped because the tool is missing" is a fact to
  report, not a pass.
- A check that ran on a different tree is not a pass. Make sure that it ran on the branch under
  review, after the last change.
- A test that passed before the implementation existed proves nothing. Ask for the failing run
  too.
- A substitute check counts only if it can fail. Point it at a target that does not exist, or
  break the input on purpose, and make sure that it exits non-zero.

## 4. Cap fix rounds

Give each problem a fixed number of attempts, for example five. After the last attempt, stop
and ask the human.

An agent in a loop of attempts drifts. It weakens the test, widens the change, or adds a retry.
A stop with a clear description of the problem costs less than the sixth attempt.

A fix can cause its own regression. After each round of fixes, run the full check again from
the start, not only the check that failed.

## 5. Expect plan defects

Each plan has mistakes: a wrong schema, a property that is a method, a command that cannot work
in this environment. An implementer that pushes back on the plan is doing its job.

- When an implementer reports a conflict, fix the plan file, then continue.
- Record each such decision, with its cost if it is wrong.
- Tell later tasks about the change. They read the plan, not the earlier chat.
- Before each task starts, read its brief against the fixes already made. A later brief can ask
  for the defect that an earlier review removed.
- Review the steps that you added yourself. The supervisor's own extra steps are not exempt.

The worst result is an implementer that bends the code to match a wrong plan, without a word.

## 6. Context hygiene

The context of a session is a budget. Each tool result stays in it until compaction.

- **Delegate noisy work.** Send broad searches, log reads and dependency research to a subagent.
  Keep only its conclusion.
- **Prefilter logs.** Send a long output to a file and read the failing lines, not the whole log.
- **Clear between unrelated tasks.** If the topic changes, start a new session or clear the
  context.
- **Pick the model and the effort for the task.** A fully specified plan runs well on a mid-tier
  model. Judgment tasks, such as a final review of a whole branch, deserve the most capable one.

## 7. Record decisions outside the chat

Chat context gets compacted, and later sessions do not see it. Write each decision where the
next reader finds it:

- In the commit message: the why of the change.
- In an ADR or a design note: the decisions that shape later work.
- In a progress ledger next to the plan: per-task status, rulings and parked items.
- In the description of the pull request: what is out of scope, and why.

Record each decision of the human in full: who decided, what, and why. Do this especially when
the human overrides a recommendation. An implementer must refuse an "approval" that another
agent relays. Only the human approves.

A long ledger gets noisy, and old entries go stale. Keep a short current-state section at the
top, and mark superseded entries.

## 8. Review the whole result once, with fresh eyes

A per-task check does not see how the tasks fit together. For example, a cache that one task
adds can poison a workflow that another task owns. At the end, give the full diff, the
plan and the spec to a reviewer with a fresh context. Then:

- Sort the findings by their effect on a user, not by the label that the reviewer gave.
- Fix the serious ones, each with a test that failed first.
- Report the minor ones to the human. Do not fix them without asking.

## Related

- `proving-test-changes`: evidence that a test change still catches defects.
- `shipping-narrow-changes`: one concern per pull request, and parked work with a record.
