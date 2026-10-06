# Proving test changes: jest and React Testing Library

The repository's AGENTS.md wins on the exact test command. These examples assume
`npx jest <path>` or `npm test -- <path>` from the frontend directory.

## A mutation run as one script

```bash
#!/usr/bin/env bash
# prove.sh: one mutation per block, restore by copy, diff at the end.
cd /abs/path/to/assets || exit 1
BACKUP=$(mktemp -d)
P=js/path/to/Component.jsx
cp "$P" "$BACKUP/"

LITERAL="if (isRunning) {"
test "$(grep -c -F "$LITERAL" "$P")" = 1 || { echo "ANCHOR NOT UNIQUE"; exit 1; }
perl -0pi -e 's/if \(isRunning\) \{/if (!isRunning) {/' "$P"
grep -n -F "if (!isRunning) {" "$P"                       # show that the mutation landed
npx jest js/path/to/Component.test.jsx 2>&1 | grep -E "^(FAIL|Tests:)|^  ● " | grep -v Console | sort -u
cp "$BACKUP/Component.jsx" "$P"

diff -q "$P" "$BACKUP/Component.jsx" && echo RESTORED
```

Notes:

- Do not use `set -e` here. A `grep` with no match exits 1 and stops the script before the restore.
- Do not pipe jest through `tail` alone. You lose the failing test names, and the pipeline exit
  status becomes the status of `tail`.
- For mutations that contain backticks or `$`, write a small perl script that uses `index()` and
  `substr()`, and end it with `die "MUTATION MATCHED NOTHING" unless $hit;`.

## Old spec against new spec

```bash
git show HEAD:assets/js/path/to/Component.test.jsx > "$BACKUP/old.test.jsx"
cp "$BACKUP/old.test.jsx" js/path/to/Component.old.test.jsx
# run each mutation against Component.old.test.jsx and Component.test.jsx, then delete the copy
```

## Async specs: which query is which claim

| Claim | Form |
|---|---|
| X eventually arrives | `await screen.findByText(...)` or `await waitFor(() => expect(...))` |
| X was already there and survived event E | `expect(screen.getByText(...))` right after E settles |

- `waitFor` polls until the callback passes. Around a persistence claim it hides a flicker,
  because it also accepts X disappearing and coming back.
- An immediate `getBy` after an explicit settle barrier catches a late arrival that `findBy`
  polls past. Keep the barrier: without it, the immediate check becomes flaky.
- `await act(async () => emit(event))` does not always flush state that a runtime applies
  through its own subscriber pipeline. Only `waitFor` or `findBy` synchronises with it. Probe
  once and record which barrier works.

## Smells specific to Testing Library

- `expect(...)` inside a shared helper. When it fails, jest names the caller. Replace it with
  `await screen.findByText(...)`, which fails with a DOM dump that names the missing text.
- A bare `await screen.findByX(...)` with no `expect`. It throws on timeout, so it is a real
  guard that looks like setup. Move it into the test that names the claim and wrap it:
  `expect(await screen.findByRole(...)).toBeVisible()`.
- `toBe` identity checks against an object that a mock factory caches per key. A rebuilt object
  can come back as the same cached instance.

## Printing state at a point in a test

```js
// temporary probe, remove before commit
console.log('PROBE afterStop', screen.getByTestId('bubble').textContent);
```

Run with `npx jest <spec> 2>&1 | grep PROBE`. If no mutation separates two variants, a probe
shows which scenario each one covers.

## Whole-suite count changes

If the total test count changes, compare per-file `it(` counts between `HEAD` and the working tree:

```bash
git grep -c "^\s*it(" HEAD -- 'assets/js/**/*.test.jsx' > "$BACKUP/head.txt"
grep -rc "^\s*it(" assets/js --include='*.test.jsx' > "$BACKUP/work.txt"
```
