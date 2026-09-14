# Reference notes

Longer-form notes on how a **dependency or toolchain** behaves — too long for a `traps.md` entry,
wrong shape for `decisions.md` because nothing was decided.

**Deliberately outside `work/`.** Everything there is either task state or a churn list that gets
appended to and pruned. A reference note is neither, and filing it there gets it read as one, pruned
as one, or picked up by a merge driver meant for something else.

## What belongs here

- How a dependency actually behaves when its documentation is thin or wrong.
- Why a build configuration is shaped the way it is, when the shape is forced by the tool rather
  than chosen.
- A platform difference that keeps coming up and needs more than three lines to state.

## What does not

| | Goes to |
|---|---|
| Something that will bite every session | `work/traps.md` — short, actionable, a hazard |
| A choice that was made, and why | `work/decisions.md` |
| Temporary code in the tree | `work/hotfixes.md` |
| How the team works | `CLAUDE.md` |

## One rule for every note here

**Say whether a claim was measured in this project or came from somewhere else.** A configuration
borrowed from another project is evidence that something works *somewhere*, not that it is right
here, and the difference matters the day it stops working. Date anything you measured.
