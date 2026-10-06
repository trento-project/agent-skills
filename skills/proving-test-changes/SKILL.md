---
name: proving-test-changes
description: Use when editing, rewriting, deleting, merging or de-mocking existing tests, when a test still passes after a change and you need to know it can still fail, when replacing assertions in an old spec with new ones, or when auditing async specs for waits that hide regressions.
---

# Proving test changes

The repository's AGENTS.md wins on how to run a single test, on tooling and on limits.
Stack-specific commands and examples are in `references/`:

- `references/jest.md` for JavaScript UI specs.
- `references/exunit.md` for Elixir specs.

## The rule

**A green suite after a test edit proves nothing.** The test passed before and it passes now.
A deleted assertion looks the same. A test change is not done until a deliberate mutation of
the production code makes the specific test fail by name.

This applies when you:

- rewrite assertions
- replace a mock with a real object
- change how a test finds an element or a record
- merge two tests, or "simplify" a spec
- delete a test you believe is redundant

It does not apply to a new test for new code. There, the failing-first run is the proof.

## Protocol

Do one mutation per run. Two mutations in one run lose the mapping from cause to failure.

1. **Back up the production file** to a scratch directory outside the repo. On a shared
   machine, use a job-scoped temp directory, because parallel jobs overwrite each other in `/tmp`.
2. **Apply exactly one mutation with a script**, not by hand. A scripted mutation is
   reversible and reviewable.
3. **Print the mutated lines.** A pattern that matched nothing gives a "passing" mutation that
   proves the opposite of what you think.
4. **Run only the affected spec.** Capture the names of the failing tests, not only the count.
5. **Check the mapping.** The mutation must fail the test that you named in advance, and
   ideally only that one. A mutation that fails five tests is too coarse to prove one assertion.
6. **Restore from the backup by copy**, never by an inverse mutation.
7. **Compare the restored file against the backup** (`diff -q`) and show the result.
   Restoration is the step most likely to go wrong silently.

### Scripting traps that produce silent no-ops

- **Guessed indentation.** Read the exact target lines first, then build the pattern from what
  you read.
- **Shell expansion inside the pattern.** Backticks and `$` inside a double-quoted one-liner get
  expanded by the shell. For those, write a small script file that uses plain string search. If
  the search matched nothing, the script stops with an error.
- **A short literal that is a substring of a longer line.** Count the matches before you
  mutate, and require exactly one. If there are two, widen the anchor until it is unique. A row
  produced by a zero-match or two-match anchor is not a result. Drop it and say so.
- **State that does not persist between commands.** The working directory and shell variables
  can reset between tool calls. Put the whole run in one script file: change directory or exit,
  make a temp directory, back up, then one `mutate, print, run, restore` block per mutation,
  then a final `diff -q`.
- **`set -e` with `grep`.** A `grep` that matches nothing exits non-zero. `set -e` then stops the
  script after the mutation and before the restore. Check exit codes explicitly instead.
- **Piping the runner through `tail` alone.** You lose the failing test's name, and the pipeline
  exit status becomes the exit status of `tail`. Filter for test names and the summary together.
- **A mutation left in place at the end of a turn.** Restore in the same script that mutates.

## Choosing mutations

Mutate the behaviour the assertion claims to guard, one claim at a time. Good mutations are the
plausible regressions of a future maintainer:

| Assertion claims | Mutation |
|---|---|
| cleanup runs on teardown | delete the cleanup |
| a dependency list is narrow | widen it with a field that must not trigger a rebuild |
| a dependency list is complete | narrow it by a field that must trigger a rebuild |
| step A runs before step B | swap their order |
| a value is forwarded | stop forwarding it |
| a branch is taken | invert the condition |

Widening and narrowing the same list are two mutations that catch two different bugs. Run both.

## The vacuous-assertion test

The protocol is also a detector. If a mutation that obviously breaks the behaviour leaves the
test green, the assertion is blind. Fix the assertion, then run the same mutation again and show
that it now fails.

Worked example: a test named "updates the thread id without rebuilding the agent" checked that
the channel object stayed the same. The test double cached one channel per topic, so a fully
rebuilt agent got the same channel back. The mutation "rebuild the agent on every change" left
every test green. The assertion changed to check the agent object itself, and the same mutation
then failed exactly that test. The before and after pair is the proof. Either half alone is an
opinion.

Smells to mutate on sight:

- Identity checks against an object that a factory or a double can cache or reuse.
- Assertions on a value that the test itself, or its own double, produced.
- Assertions that read a value back from its own producer. "The payload id equals the agent's
  current id" passes for any id, because the agent wrote both sides. The real claim ("a fresh id
  per run") needs two runs and an inequality between them.
- Negative assertions ("was not called") with no positive twin in the file.
- Any assertion for which you cannot state a one-line failure scenario.
- An assertion inside a shared setup helper. When it fails, the runner blames the caller. Keep
  the precondition, but turn it into a wait that fails with a clear message about what is missing.
- A wait with no assertion around it. It reads as setup, but it fails the test when the
  precondition never arrives. A reader can delete it as dead code. Move it into the test that
  names the claim and make the intent explicit.

## A surviving mutation is not automatically a coverage gap

"Zero tests failed" has three causes, and only one is a hole in the suite. Do these three checks
before you write a new test.

1. **Is the mutation observable at all?** Some edits preserve behaviour. If no reachable flow
   shows a difference, there is nothing to kill. State the user-visible symptom first. If you
   cannot, the mutation is inert.
2. **Does another tool already catch it?** Run the linter and the compiler on the mutated file.
   A mutation that only the linter catches is covered by the linter. Then find the lint-clean
   variant of the same mutation. That variant is what a real regression looks like.
3. **Does the new test pass against unmutated production code?** If it fails, you found a bug,
   not a coverage gap. Stop and report it. The fix goes into production code, not into the spec.

Report each survivor with the cause that applies. "Zero kills" alone is ambiguous.

## A mutation that dies can still guard a bug

A kill proves that the suite notices the change. It does not prove that the unmutated side is
correct. If the only evidence for current behaviour comes from fixtures that the test builds
itself, a clean single-kill row can lock in a defect.

Worked example: a strict id check killed exactly one test, by name, on the first try. But the
real server event had no id field. The test factory invented one, so the strict check dropped
every real error event in production.

For each new strictness, ask: **what on the production side supplies this value, and did I read
it?** Read the emitter's schema, not the double. In a mutation row that asserts a wire fact, name
the file and the function of the producer. The next reader can then check it in one step.

## Async assertions: arrival barrier or persistence claim

In an async spec, "wait until X is true" and "X is true now" are different claims.

| Claim | Correct form | Why the other form is wrong |
|---|---|---|
| X eventually arrives (arrival barrier) | wait or poll until X | An immediate check reads state too early and fails on timing, not on behaviour. |
| X was already present and survived event E (persistence claim) | immediate check right after E settles | A poll passes if E wipes X and something restores it later. The regression goes unreported, and a real failure burns the full timeout. |

Apply this test: was X already proven present earlier in the same test? If yes, the second check
is a persistence claim. Do not wrap it in a wait. If you are not sure, print the state at both
points instead of guessing.

An immediate check after an explicit settle barrier is stronger than a poll, because the poll
also accepts a late arrival. The immediate check and the barrier are a pair: remove the barrier
and the immediate check becomes flaky instead of strict.

A framework's own "await" does not always settle the state you assert on. Some runtimes apply
events through their own pipeline. Probe once and record which barrier works. Do not infer it
from the API name.

## Comparing an old spec to a new one

When you replace assertions, run the mutation set against both the old spec (extract it from
version control) and the new one. There are three outcomes:

- Old fails, new fails: equal strength. The change is safe.
- Old passes, new fails: the change closed a blind spot. Say so, with the numbers.
- Old fails, new passes: **you weakened the suite.** The change is wrong.

Do this before you claim that a rewrite is an improvement.

### Moving an assertion to a better level

If you delete an integration assertion because a new unit test covers the same claim, count
kills in three states:

1. Integration assertion present, no unit test.
2. Unit test added, integration assertion still present.
3. Unit test added, integration assertion removed.

Coverage stays the same only in one case: state 3 equals state 1, and the surviving kill is the
test you meant.

### Mutate the wiring, not only the logic

A unit test cannot see how its subject is called. "Compute X here, pass it there" has two
mutation sites. Break the logic in one run. Delete the hand-off (the argument or property that
carries X) in a separate run. The unit test cannot fail on the second mutation, by construction.
That is the reason a composition-level test exists.

### Coverage-neutral refactors

A change to test helpers can be correct and buy zero kills. Report it as what it is: it removes a class of
future mistake, not a current gap. If no mutation separates two variants, a printed state probe
can still show which one tests the real scenario. Say that the probe is the evidence, and that it
proves fidelity, not coverage.

### Do not credit your own change without checking

A kill count can change because someone else edited the spec while you worked. Diff the spec
file too, not only the production file, before you explain a change in numbers. If a whole-suite
test count changes, find the cause in version control before you report it.

For flaky suites, see the `evidence-first-debugging` skill on paired runs in both orders.

## Reporting

Put the mutation, the test it killed and the restore in a table. Use numbers, not adjectives.
"Verified" without a mutation table is not verification.

If a prediction turns out wrong when you run it, say so plainly. Then find the mutation that does
separate the two cases. Swapping in different evidence without flagging the correction is how a
wrong claim survives.

## Related

- `test-double-boundaries`: what the replacement assertion targets, and which seam to substitute.
