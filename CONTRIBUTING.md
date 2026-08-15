# Contributing

This is the default guide for every BaryoDev project. Some repositories have their own
`CONTRIBUTING.md` with rules specific to that codebase; where one exists, it wins.

Contributions are welcome, including small ones. Fixing a typo in a doc comment is a real
contribution and does not need a discussion first.

## These projects are unfunded, and there is no paid work here

Worth saying plainly, because the question comes up and I would rather answer it once than
leave anyone waiting.

Everything under this organisation is unpaid and voluntary, mine included. I build these
because I enjoy building them, not as a business, so there is no budget to pay contributors
from and offers to implement an issue for a fee will be declined. That is not a comment on
anyone who asks, it is just the situation, and I would rather you knew before spending time
on a proposal.

If you want to work on something here, take an issue and open a pull request. That is the
whole process and it is open to anyone.

One related note, since detailed issues invite this. Many issues here carry a full diagnosis:
the file, the line, the mechanism and often the suggested fix. That is deliberate, so a
stranger can start without asking permission. It also means a comment restating the issue back
does not tell me anything I can act on. The comments worth writing are the ones that add
something: what the issue got wrong, what it missed, or a question about the part that is not
specified. Those get answered quickly.

## Before you start

**For a bug, open an issue with a reproduction.** A failing test, a small program, or the
exact calls that produce the wrong result. A reproduction is worth more than a careful
description, because it turns a discussion into something measurable.

**For a feature, open an issue first.** Not to gatekeep, but because most of these projects
have a constraint that decides design questions before they get argued, and it is better to
find that out early than after you have written the code.

## Working on a change

1. Fork, then branch: `fix/short-description` or `feat/short-description`
2. Make one change per pull request. A fix and a refactor in the same diff are hard to review
   and harder to revert
3. Add a test that fails without your change. If you cannot write one, say so in the
   description and explain why. [TESTING.md](TESTING.md) is the worked version of this
   rule: real before and after examples from these repositories, the mutations that tell
   them apart, and the cases where "I could not write one" is the right answer
4. Run the full test suite locally before pushing
5. Update `CHANGELOG.md` if the repository has one

## Commit messages

Conventional commits, and explain **why** rather than what. The diff already says what.

```
fix(store): stop the reader advancing past an unread result set

The marker told the executor to skip NextResult, which is only sound
while the SQL genuinely returns nothing.
```

Do not add `Co-Authored-By` or AI-attribution trailers.

## Pull requests

Link the issue. Say what you changed and why. If you considered a larger or more structural
fix and chose not to take it, say so and explain the reasoning: that is useful information
for the reviewer, not a weakness.

If CI has a check you do not understand, ask rather than working around it. Most of these
projects gate something specific (a public API surface, an allocation count, a bundle size),
and those gates exist because the thing they protect is the reason the library is worth using.

## Things that apply across these projects

- **Published packages have a public API surface that is part of the contract.** Renaming an
  export or changing a signature is a breaking change even when every test still passes
- **Zero-dependency is a promise where it is claimed.** Adding a runtime dependency to a
  package that advertises none needs a conversation first
- **Backward compatibility matters more than tidiness.** Deprecate before removing, and
  removals wait for a major version

## Licences

Licences vary by repository, and sometimes within one. Check the `LICENSE` file and any
per-package licence before contributing. Contributions are accepted under the licence of the
file you are editing.

## Reporting security issues

Do not open a public issue. See [SECURITY.md](SECURITY.md).

## Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). The short version is: be decent, and argue
about the work rather than the person.
