---
name: shipping-narrow-changes
description: Use when a piece of work is growing past one reviewable pull request, when preparing a change for review, when choosing between a small and a larger variant of the same fix, or when splitting or restacking a series of dependent branches.
---

# Shipping narrow changes

The repository's AGENTS.md wins on size limits, branch names, remotes and merge rules. If the
repository has a CONTRIBUTING file, read it too.

## 1. The rule

One concern per pull request, within the size norm of the repository.

A branch that collects a whole subsystem before anything lands is hard to review and cannot
ship. Time spent on later pieces is time that the first useful piece is not in anyone's hands.
One narrow change that merges is worth more than one broad change that waits.

Signs that a branch carries more than one concern:

- The description needs "and also".
- A reviewer can approve one part and reject another.
- A dependency bump, a fix and a refactor share a commit.
- A test change in the branch has nothing to do with its title.

## 2. Carve the first shippable slice

Find the piece that is useful on its own, put it on its own branch from the current main branch,
and ship it.

Say at the start what ships first and what gets parked. The human then knows what to review
now, and what is waiting.

If a later piece depends on an earlier one, stack the branches (see
`references/stacked-prs.md`). If two pieces are independent, do not stack them. Base each one on
main, so that each can merge in any order.

Prefer a note in the pull request body to a detour that perfects the change. "Known limit: X,
follow-up planned" is a reviewable sentence. A second concern in the same diff is not.

## 3. Minimal variant first

Often there are two ways to make the same fix: a small local change, and a larger refactor.

1. Measure both against the same check, for example the same test or the same mutation.
2. If both measure the same, present the smaller one first.
3. Show the measurement that proves that the larger one buys nothing more.
4. Offer the larger one only as a separate follow-up.

A refactor that the fix does not need is a second concern.

## 4. Show the diff, then wait

Before you apply a change that the human has only heard described, show the diff. Show hunks,
not prose. Then wait for a "go".

The human can edit the files between turns. A comment that you added can be gone, an assertion
order can be reverted, a block can be reworded. So:

- Re-read the working tree before you build the next variant.
- Diff against the working tree, not against a scratch copy that you saved earlier.
- If the human reverted one of your changes, note it in one line and move on. Do not argue it
  again.

## 5. Park with a record

Parked work without a written record is lost. A stash or a branch name does not say why the
work exists or what it is waiting for.

For each parked item, write down:

- Where it is: the branch name, or the label of the stash. Stash indexes move, so use the label.
- What it holds: the files and the purpose.
- Why it is parked, and what it waits for.
- What to expect at unpark time, for example a conflict in a file that moved on since.

Put the record where the next session finds it: the notes of the repository, the description of
a draft pull request, or the team's tracker.

## 6. Estimate in wall-clock hours, early

Give the estimate in hours at the start, before the work grows. If the estimate reaches about
four hours, re-scope. Do not try to go faster. A long estimate usually means that the work holds
more than one concern.

## 7. Before you ask for review

- The branch contains only the commits of this concern. Check the log against the base.
- The diff against the base contains only the files of this concern.
- The checks that AGENTS.md names pass on the branch, and you have their output.
- The description says what changed, why, how it was tested, and what is out of scope.
- If the branch is part of a stack, the description names the branch below it.

## Related

- `proving-test-changes`: the evidence that a smaller variant covers the same defects as the
  larger one.
- `references/stacked-prs.md`: restacking dependent branches safely.
