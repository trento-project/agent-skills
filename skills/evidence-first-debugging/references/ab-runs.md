# Paired A/B runs

Use this when you must decide whether a change makes a suite flakier than its base.

## Protocol

1. Get two trees: the base and the change. Use two worktrees, or a WIP commit that you check out
   and back. Do not use a shared stash, because other sessions can pop it.
2. Pick the seeds before you start, and write them down.
3. For each seed, run the base and the change. That is one pair.
4. Run half of the pairs with the base first, and the other half with the change first.
5. Record the failures per half, per order.
6. Compare the rates. Do not compare single runs.

```bash
# Elixir: same seed for both halves
mix test --seed 12345 > base-12345.log 2>&1
mix test --seed 12345 > change-12345.log 2>&1

# jest: randomized order with a fixed seed
npx jest --randomize --seed=12345 > base-12345.log 2>&1
```

## Results table

| Pair order | Pairs | Base failures | Change failures |
|---|---|---|---|
| change first | 5 | | |
| base first | 5 | | |

Read the table by column and by row. If the first half fails more in both orders, the order
explains the result, not the change.

Example of that artifact, from a real measurement:

| Pair order | Pairs | Base failures | Change failures |
|---|---|---|---|
| change first | 5 | 1 | 5 |
| base first | 5 | 8 | 4 |

The first row alone looks like a clear regression. The second row reverses it.

## Cheaper corroboration

Try these before more full-suite pairs:

- **Run the suspect module alone across many seeds.** If it is green each time, the flake needs
  another module next to it.
- **Delete the new file and compare the rate.** If the rate does not change, the file is not the
  cause.
- **Rule it out by argument.** For example, ExUnit runs every `async: true` module before any
  `async: false` module. A new sync module cannot disturb async tests that already finished.

## Flakes compared with pollution

- A flake: a small number of failures, a different set on each run, the same on a clean base.
- Pollution: hundreds of failures that start at one moment, the same set on each run. Check the
  state (database rows, caches) before you run pairs.
