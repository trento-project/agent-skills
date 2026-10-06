# Proving test changes: ExUnit

The repository's AGENTS.md wins on the exact test command and the database setup.

## A mutation run as one script

```bash
#!/usr/bin/env bash
# prove.sh: one mutation per block, restore by copy, diff at the end.
cd /abs/path/to/repo || exit 1
BACKUP=$(mktemp -d)
P=lib/my_app/runner.ex
cp "$P" "$BACKUP/"

LITERAL="if active_run_id == run_id do"
test "$(grep -c -F "$LITERAL" "$P")" = 1 || { echo "ANCHOR NOT UNIQUE"; exit 1; }
perl -0pi -e 's/if active_run_id == run_id do/if true do/' "$P"
grep -n -F "if true do" "$P"
mix test test/my_app/runner_test.exs 2>&1 | grep -E "^\s+[0-9]+\) test|tests?, [0-9]+ failures?"
cp "$BACKUP/runner.ex" "$P"

diff -q "$P" "$BACKUP/runner.ex" && echo RESTORED
```

- `mix test path/to/file_test.exs:LINE` runs one test. Use it to confirm the mapping.
- A mutation that does not compile is not a kill. Check for a compile error in the output before
  you count the result.
- Run `mix compile --warnings-as-errors` and `mix credo` on the mutated file too. A mutation that
  only a warning catches is covered by the compiler, not by the suite.

## Message timing: windows, not sleeps

- `assert_receive msg` waits up to the default timeout (100 ms unless configured). A wider
  window is an arrival barrier.
- `refute_receive msg, timeout` is a persistence claim over a time window. A message that is
  late by more than the window passes, so the check can hide a slow regression.
- A test that waits for a production timeout must inject a short timeout through config or an
  argument. A test whose `Process.sleep` or `assert_receive` window must exceed a hard-coded
  production value fails or passes by timing, not by behaviour. Mutating that value proves it.

## Async and sync modules

- ExUnit runs every `async: true` module before any sync module. A new `async: false` module
  cannot disturb an async test that already finished.
- With the Ecto SQL sandbox, a process that the test spawns needs shared mode or
  `Ecto.Adapters.SQL.Sandbox.allow/3`. A mutation that moves work into a new process can fail
  for sandbox reasons, not behaviour reasons. Read the error before you count it as a kill.

## Old spec against new spec

```bash
git show HEAD:test/my_app/runner_test.exs > test/my_app/runner_old_test.exs
perl -pi -e 's/defmodule MyApp.RunnerTest/defmodule MyApp.RunnerOldTest/' test/my_app/runner_old_test.exs
# run each mutation against both files, then delete runner_old_test.exs
```
