---
name: test-double-boundaries
description: Use when deciding what to mock and what to assert on in a test, when replacing a mock of first-party code, when a test double contains logic or invents data, when judging whether an assertion targets the unit's own contract or a collaborator's internals, or when choosing how a UI test finds elements.
---

# Test double boundaries

The repository's AGENTS.md wins on test tooling and on its conventions for doubles. Stack
examples are in `references/`:

- `references/jest.md` for JavaScript and React specs.
- `references/mox.md` for Elixir specs.

People often confuse two questions:

1. **Which seam do I substitute?** That is, what gets faked.
2. **Which observable do I assert on?** That is, what gets checked.

A correct answer to the first question does not give a correct answer to the second. The most
common bad refactor removes a mock and then, without the mocked method, asserts on whatever
else is observable.

## 1. Seam selection

Preference order, best first:

| Seam | Use it for |
|---|---|
| A real object over a fake transport or I/O | A collaborator that you own, whose only untestable part is I/O (socket, HTTP, clock, file system). Fake the I/O and keep the object. |
| An injection point that already exists | Context providers, dependency injection, factory parameters that production code already accepts. Search before you invent one. Some exist only for tests and stories. |
| A module mock | A third-party dependency that you cannot touch otherwise. |
| A hand-written double of your own code | Almost never. See below. |

### Do not mock code you own

A hand-written double that reimplements the real object's behaviour is a second implementation
of the contract with no test of its own. When the real object changes, the double keeps the old
behaviour, and the suite stays green against a fiction.

Two signs that you have one:

- The double contains logic: a replace-or-merge rule, a status emission, an ordering guarantee.
  Each such line duplicates an invariant.
- A test asserts on a value that the double itself emits. That test proves that the double works,
  not the production code.

### Timing claims push the seam lower

Some claims are about when or whether work stops: "cancel stops the task in flight", "teardown
does not block the caller", "the connection keeps answering during a run". A double at the
nearest adapter can only record that a function was called. The interesting behaviour lives in
the real stack between the caller and the edge of the system. Put the double at the lowest
external boundary and run everything above it for real.

Two shapes that work:

- **Fake the leaf collaborator and park it.** The fake tells the test that it was called.
  Then it blocks until the test releases it or a timeout expires. The test gets a real run in
  flight, with the real supervisor and server around it, and no network.
- **Fake the transport under the collaborator.** Sometimes the code builds the collaborator
  itself from configuration. Then there is nothing to swap. Park one layer lower, at the HTTP client.

Rules that make this safe:

- **Notify, never sleep.** Wait for the "called" notification before you act, so that the run
  is provably live.
- **Bound the park.** The timeout turns "cancel did not work" into a failed assertion instead of
  a hung CI job.
- **Restore global state in teardown**, and know which process runs the teardown.

### Global runtime state: the seam is the runtime itself

Some failure modes have nothing to inject. "The registry on this node is gone" is a check inside
a library function, with no object, transport or configuration key to replace. A stub of the
wrapper that reads it only proves that the wrapper was called.

Stop the real component, in a test that does not run in parallel with others. Then assert the
precondition ("the registry is unavailable") before the claim under test. Without that check, a
teardown that silently failed leaves you asserting the normal path. Watch the test fail before
the fix too, because this shape can pass for the wrong reason.

If a value-level seam exists, use it instead. This shape is for conditions that live in the runtime.

### Do not add a production seam only for tests

An injectable factory property, a "set instance" hook, an exported mutable singleton: if it has
no production caller and no precedent in the codebase, it is test infrastructure in the shipped
API. Prefer a real object over a fake transport, which needs no production change.

### Do not centralise a heavy wrapper in shared test utilities

A shared helper that wraps a provider pulls the provider and its whole import graph into every
spec that imports anything from that helper module. Three one-line wraps inside existing helpers
cost less than one shared helper.

## 2. Assertion targeting

**Assert on the contract of the unit under test, not on how a collaborator implements it.**

If a component must "disconnect the agent on teardown", assert on the agent's disconnect call.
Suppose that you assert on the channel that the agent leaves internally. A refactor of the agent
breaks that test, but the component is still correct. And that link usually has an owner already: the
agent's own suite tests that disconnect leaves the channel.

Before you assert one layer down, search the collaborator's spec. If the link is owned there,
asserting it again upstream buys nothing and adds a false-failure coupling.

**Exception: no handle exists.** An integration test that never gets a reference to the
collaborator has only the transport to observe. There, a transport assertion is correct, because
the fact under test is a transport fact.

### Spy on real objects

Removing a module mock does not mean removing the assertion that used it. Get a handle on the
real instance and spy on it, with a spy that calls through. You get the original assertion back,
on a real object, with real side effects. The old assertion was rarely wrong. The object was.

### A handle when the unit renders nothing

A pure wiring component has no output of its own. Its output is what it passes to the hook or
adapter that it wires up. Keep that one mock and read the arguments of its last call. That is the
real output surface, and identity checks on it mean something.

### Identity checks and caching

An identity check means something only for a source that can return a different object. Test doubles often
cache: a fake socket that keeps one channel per topic returns the same object whether or not the
caller was rebuilt. Read the double's factory before you rely on identity, and mutation-test the
assertion (see `proving-test-changes`).

### The mirror problem: a helper that derives the reply from the request

A helper that computes a fake server reply from the values the client just sent can never detect
a correlation defect. "The reply matches the request" is then true by construction, in the
helper and only there.

| Fix | What it buys |
|---|---|
| The helper takes the sent request as input | Nobody can pair a reply with the wrong ids by hand in future tests. Usually no change in coverage today. |
| Assert ids across two requests ("the second run id differs from the first") | The real coverage. This kills the "reuse one id forever" mutation. |

Do both, and report the first one as future-proofing, not as coverage.

The general rule: **a double can expose a defect only in values that flow through it, never in
values that it makes up.** Before you trust a test to cover a correlation, ask which side of the
wire each id came from.

### The worse variant: a field the real producer never sends

Worked example: a client filter dropped any terminal event whose run id did not match the run in
flight. It also dropped events with no run id, on the premise that "the server always stamps
the run id". The test factory added a run id to every event, and every test passed. The real
server struct had no run id field for that event. In production every error was dropped, the run
never settled, and the spinner never stopped.

Signs, cheapest first:

- **A required field in a factory that the producer's schema does not have.** Open the producer's
  type (struct, proto, OpenAPI document, interface), not another test.
- **A comment in a double that states a wire fact.** Treat it as an unverified claim and check it.
- **A test that pins strictness** whose only evidence for "the strict case cannot happen in
  production" comes from the same helper that builds the events.

A factory builds what the wire carries, including the fields the wire omits.

### Negative assertions

A "was not called" assertion also passes in three wrong cases: the spy is on the wrong object, the
name is misspelled, or the feature is gone. Pair every negative assertion with a positive one in the same file
that proves the spy is attached to something real.

## 3. Finding elements in UI tests

Prefer the accessible role with its name, then the label, then the visible text. Use a test id
only as the last resort. A role query pins the accessibility contract. A test id pins nothing that
a user can perceive.

Before you delete a test id from production markup, search the end-to-end suite for the exact
string. Include specs, page objects and fixtures. Report the result either way. "No end-to-end test
uses it" is a claim that needs a search behind it.

Component mocks render visible text, not test ids, so that tests can find them by text.

## Related

- `proving-test-changes`: the mutation protocol that shows a seam or assertion swap did not
  weaken the suite.
