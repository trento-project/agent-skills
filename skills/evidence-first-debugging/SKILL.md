---
name: evidence-first-debugging
description: Use when failures appear that the diff does not explain - many tests failing at once, CI red across unrelated specs, behaviour that changed after a dependency, image or package upgrade, a suspected flaky test, or a bug report from an environment you cannot reproduce.
---

# Evidence-first debugging

The repository's AGENTS.md wins on commands, services and environment details. Stack examples
are in `references/ab-runs.md` and `references/reading-dependency-source.md`.

## 1. The rule

Each link from the symptom to the cause is something that you observed, not something that you
inferred. For each link, cite the file and the symbol, or the command and its output. Do not cite
line numbers, because they move.

A chain with one inferred link is a hypothesis. Report it as a hypothesis.

## 2. Environment before code

Before you read the diff, find out whether the diff is the cause.

- Compare against the last CI run of the base branch, on the same job. If the parent commit fails
  in the same way, the change is not the cause.
- Many failures that appear suddenly, on a commit that passed an hour earlier, mean that state
  changed, not code. Look at the database, caches, containers, the toolchain and the installed
  packages.
- A green build of an artifact does not prove that the artifact works. A package manager can
  substitute a different package that satisfies the same requirement and still exit 0.
  Inspect what the artifact contains, for example the libraries that a binary links against.

Worked example: a test run that passed in the morning failed in hundreds of tests in the
afternoon, on the same commit. The cause was rows left behind in the test database by a process
that ran against it. Each setup that deleted a table hit a foreign key on one of those rows.
The test sandbox did not own them, so it did not roll them back. A query of the row counts per table found it in one step. A bisect of
the code finds nothing in this case.

Do not "fix" a state problem with a code change. For example, do not change parallelism flags,
add retries or raise timeouts. Restore the state, then re-run.

## 3. Reduce to one symptom

When many specs fail, do not read the first one. Group the failure messages and find the
dependency that they share:

- A service that never started (every failure needs the same port).
- A missing library or a library with the wrong version.
- A shared fixture or seed.
- A clock or time zone.

Worked example: end-to-end shards went red with three different messages in unrelated specs. A
request error on one port, a version field that read "N/A", and an undefined status code. All
three meant "one backend service never came up". The container build was green. The cause was
a runtime library mismatch inside the image.

## 4. A/B a change against its base

To claim that a change makes a test flakier, you need paired runs, not one red run.

- If the runner supports seeds, use the same seed for both halves of a pair.
- Run enough pairs to see a rate, not an anecdote.
- Run the pairs in both orders. Whichever half runs first can flake more, because the machine is
  colder or busier. With one order only, a clean base can look like a regression.
- Before more suite runs, try the cheaper evidence. Run the suspect module alone across many
  seeds. Delete the new file and compare the rate. If the runner's scheduling makes an
  interaction impossible, rule it out by argument.

The protocol and a results table are in `references/ab-runs.md`.

## 5. Read what shipped, not what was announced

Release notes, changelogs and issue titles describe intent. The installed package is the fact.

- Read the installed source or the built output of the dependency at the exact version in the
  lock file.
- Before you claim that a version bump fixes something, diff the two versions at the code that
  matters.
- When a call seems to have no effect, check the signature of what actually runs. An argument
  that the callee does not accept is dropped without an error in some languages.

Worked example: a UI runtime passed an abort signal as a third argument to an agent's run method.
The installed method took two parameters, so the signal was discarded, and "stop" never
unsubscribed the stream. Printing the function source at runtime proved it in one line. The
newer release was also checked, as a tarball, before anyone relied on "the bump fixes it". It
did not.

Worked example: a client failed TLS verification against a server, but command-line tools on the
same machine connected without error. The HTTP library resolved the host name through DNS first,
and the tools used the hosts file. The two paths reached different servers. Printing the resolved
address and the peer certificate fingerprint from inside the failing process proved it. Earlier
checks of CA content, TLS options and patched libraries all passed, because they were not the
cause.

The lesson of the second example: reproduce from inside the failing process, with its own
libraries and its own resolution path. A tool that "works" can take a different path.

Procedures are in `references/reading-dependency-source.md`.

## 6. Prove the fix by removing it

Proof of a fix needs two runs of the check that failed: red without the fix, green with it.
"It passes now" without the red half proves only that it passes now.

For a fix in configuration or environment, the same rule applies. Show the failing state, apply
the change, and show the passing state, with the same command.

## 7. Report

Report in this order:

1. The symptom, with the exact error text.
2. The causes that you ruled out, each with the evidence that ruled it out.
3. The cause, with the chain of observed links.
4. The fix, with the red and green runs.
5. What is still not proven.

The last item is required. An empty "not proven" list is a claim too, so make sure that it is
true.

## Related

- `proving-test-changes`: the mutation protocol, for proof that a test catches the defect.
- `test-double-boundaries`: when the defect hides in a test double that invents data.
