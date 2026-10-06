# Stacked pull requests

A stack is a series of branches, each based on the one below it. Each branch gets its own pull
request, and each pull request targets the branch below it. The bottom one targets main.

## Before each rebase: back up

```bash
git branch backup/<name>-<yyyymmdd> <name>
```

A backup ref costs nothing. It lets you compare the result and undo a wrong rebase without the
reflog.

## Restack with explicit commits

```bash
git rebase --onto <new-parent> <old-parent> <branch>
```

- `<new-parent>`: the commit that the branch must now sit on, for example the new tip of the
  branch below it.
- `<old-parent>`: the commit that the branch sat on before. Use the backup ref of the branch
  below, or the commit that you recorded.

Do not restack with a bare `git rebase` or with `git pull --rebase`. Without an explicit
`<upstream>`, git uses `--fork-point`, which reads the reflog of the upstream branch. After the
branch below was amended or rebased, it can pick the wrong base, replay a commit that is already
there, and conflict. `git rebase --onto` with explicit commits avoids the guess.

## Check that a restack is needed

Even when main did not move, the human can amend a lower branch between turns. Before you say
that a restack is a no-op, compare the real commits:

```bash
git rev-parse <lower-branch>
git merge-base <lower-branch> <upper-branch>
```

If the two differ, the upper branch is not on the current tip of the lower branch.

## Prove that a rebase changed nothing

```bash
git show <backup-ref> | git patch-id --stable
git show <branch>     | git patch-id --stable
```

The same patch id means the same change. If the id moved, read the diff of the two patches.
Often a context line changed because main changed near the hunk.

For a whole branch:

```bash
git range-diff <old-base>..<backup-ref> <new-base>..<branch>
```

## Push

```bash
git push --force-with-lease origin <branch>
```

Use `--force-with-lease` only, never `--force`. If someone else pushed to the branch, the push
fails instead of deleting their work.

## Known limits of the hosting platform

- When the bottom pull request merges, retarget the next one to main. GitHub does this
  itself if the merged branch is deleted. Then restack it onto main with `--onto`, with the old
  bottom tip as `<old-parent>`.

## A change that does not belong in the stack

If a fix is independent of the feature in the stack, give it its own branch from main. Do not
slide it under the stack to make later code "born fixed". Whichever change lands second then
adapts to the first. Record that follow-up in the description of both pull requests.
