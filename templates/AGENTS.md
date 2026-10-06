<!--
Keep under 150 lines. Add a rule the second time a mistake happens. Prefer a lint rule to a prose rule.
Put a CLAUDE.md next to this file that contains only: @AGENTS.md
-->

# <Repository name>

<!-- What this is: two to four sentences. The product, the stack, the systems it talks to. -->

## Commands

<!-- Exact commands, in fenced blocks: start dependencies, the checks that CI runs, tests. -->

```bash
<start dependencies>
<check 1>
<check 2>
<run all tests>
<run one test file>
```

## Architecture map

<!-- One line per top-level directory that an agent needs: what lives there. -->

- `<dir>/`: <what>

## Conventions

<!-- Rules that a linter cannot check. Each one short. Add the reason when it is not obvious. -->

- <convention>

## Testing

<!-- Test setup traps, how to find flaky or polluted state, the proof that a test change can fail. -->

- <testing rule>

## Pull requests

<!-- Size norm, commit message rules, review rules. If CONTRIBUTING exists, copy from it. -->

- <rule>

## Boundaries

Ask first:

- <action that needs a human's go, for example adding a dependency>

Never:

- <forbidden action, for example committing secrets or pushing to main>

## Skills

<!-- Point to the generic skills and to this repository's own skills in .agents/skills/. -->

Generic process skills live in [trento-project/agent-skills](https://github.com/trento-project/agent-skills).

## Open team decisions

<!-- Questions the team has not settled. List them so that agents do not treat them as rules. -->

- <open question>
