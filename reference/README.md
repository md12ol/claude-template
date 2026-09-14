# Reference notes

Longer-form notes on how a **dependency or toolchain** behaves — too long for a `traps.md` entry,
wrong shape for `decisions.md` because nothing was decided. **Deliberately outside `work/`**, where
everything is either task state or a churn list, and where such a note would be read as one, pruned
as one, or picked up by a merge driver meant for something else.

**What belongs here:** how a dependency actually behaves when its documentation is thin or wrong;
why a build configuration is shaped the way it is when the shape is forced by the tool rather than
chosen; a platform difference that keeps coming up and needs more than three lines to state.
Anything that will bite every session is a `work/traps.md` entry instead, a choice that was made is
`work/decisions.md`, temporary code is `work/hotfixes.md`, and how the team works is `CLAUDE.md`.

**One rule for every note here: say whether a claim was measured in this project or came from
somewhere else.** A configuration borrowed from another project is evidence that something works
*somewhere*, not that it is right here, and the difference matters the day it stops working. Date
anything you measured.
