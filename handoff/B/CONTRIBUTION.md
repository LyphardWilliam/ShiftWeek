# B contribution facts

GitHub author: `chmmmg`. Full names and student IDs belong in the checked course PDF, not this public record.

| Commit | Actual change |
| --- | --- |
| `e4f780a` | Shared SwiftData models for jobs, shifts and payslips |
| `ac60b29` | Shared model container with an explicit App Group fallback |
| `a196531` | Shared calendar, colours and formatting |
| `3259062` | Three SwiftData repository implementations for ShiftCore protocols |
| `a3cd718` | Read-only Widget provider and small/medium layouts |
| `f15058a` | Six complete Today/Week/form files and integration evidence |

A moved the six B screen files into production in `e722197`, then connected them through the real App assembly. The hashes in [source-manifest.json](source-manifest.json) preserve the link to B's original source. A also implemented Settings and Pay; C implemented ShiftCore rules, protocols, use cases and package tests.

`04891c8` synchronizes C dependencies from main. `0b3d527` merges B's earlier delivery. Both have multiple parents and are merge commits, not extra features.

At main `5d44328`, the reachable history contains 6 B non-merge commits and 2 B merge commits. B's 12 current production Swift files contain 1,316 physical lines, including blank lines/comments and final unterminated lines. This is current file responsibility, not Git-added lines, independent authorship of reference material, hours or a contribution percentage. Later finish-branch documentation commits are separate until merged.

The current finish work uses `feat/b-demo-delivery` for review by A. Record the actual PR and merge when they exist. Commit history does not by itself prove peer review, individual authorship of reflections or final submission.
