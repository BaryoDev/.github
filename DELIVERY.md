# How work ships here

These projects are built with heavy AI assistance. That is not a disclaimer, it is the reason this
document exists.

Code arrives fast enough that reading it stops being a sufficient check. The failure mode is not
code that looks wrong. It is code that looks entirely reasonable and is quietly untrue:
documentation describing a feature that was never implemented, a test that passes against the bug
it names, a dashboard number nobody can verify.

**"I reviewed it carefully" is unfalsifiable.** What a stranger can check is a record: this ran,
here, and here is the log. Every gate below exists because it caught something real, and each one
is cited. A gate that has never caught anything is ceremony, and should be deleted rather than kept
for the look of the thing.

The rule everything else follows from:

> Prefer observing a running system over reasoning about a static one.

---

## The phases

1. **Brainstorm to a written spec.** Questions one at a time, two or three approaches with a
   recommendation, then a spec file in the repo. The spec is the authority the plan argues from;
   when the plan and the spec disagree later, the spec wins.
2. **Plan into bite-sized tasks.** Exact file paths, real code, each task with its own test cycle.
   Before any execution, scan the plan for conflicts between tasks and write the findings down.
3. **Build task by task, fresh context each time.** One implementer per task, a reviewer on that
   task's diff, then a fix loop. Decisions get recorded as rulings with what they cost if wrong, so
   a later reader can tell a deliberate choice from an oversight.
4. **Review the whole branch.** Not the same as the per-task reviews, and not optional.
5. **Deploy to the playground and look at it.** A real server, behind a real proxy, at a real path.
   Then actually use it. Load the page, click the thing, read the database.
6. **Publish, gated on the above.** The pipeline refuses to publish a build the playground has not
   run.

---

## The gates, and what each one caught

### Whole-branch review

A reviewer that sees the entire diff at once, after the per-task reviews have passed.

**Caught:** a `Provider` config option that the README, `SECURITY.md` and the marketplace listing
all told users to set to Azure Speech, and that nothing in the code read. Setting it booted cleanly
and kept using the free endpoint. The option and the composer lived in different tasks, so no single
task's diff contained both.

A silently inert setting is worse than a missing one. The missing one fails at bind time; the inert
one manufactures confidence.

### Grep for the claim, not the files

After any finding about something the project asserts, search for the assertion across the whole
repo rather than fixing the files the reviewer named.

**Caught:** three further copies of the same false claim after the review's two were fixed,
including a live demo page selling a paid tier that did not exist. It sat in `tests/`, which no
documentation pass would open. A reviewer scoped to a diff sees where a claim was changed, never
everywhere it was made.

### Mutation check

Before trusting a new test, break the thing it covers and confirm it fails. A test written after
the code passes immediately, which proves nothing.

**Caught three times, twice in work written the same day:** a liveness assertion reading
`Ceiling > Floor` that passed against the exact over-claim it described; a path-base test that
asserted a variable was *declared* rather than *used*; and three shipped tests satisfied by their
subject's own header comment.

**A test that passes against the bug it names is not a test.**

### Gate the promise the project makes

Every gate above is generic. This one is not, and it is the one most worth spending effort on:
**whatever the project's headline claim is, something automatic has to check it.** A claim nothing
tests is marketing.

| Project | The promise | The gate |
|---|---|---|
| Verdict | zero allocation on the hot path | an allocation budget asserted in CI, not a benchmark you read |
| read-aloud | a page reads itself aloud | the deployed site returns real `audio/mpeg` over 10 KB |
| umbraco-pwa | the site is installable and works offline | the live manifest parses and carries name, start_url, display, icons |
| BaryoVM | a deploy is one command | the built binary runs that command against a real VM |
| Talaan | a spreadsheet round-trips | write a file, read it back, compare |

If you cannot write this row for a project, the project does not yet know what it is promising.

### Test in the configuration you ship

Run the suite against the optimised build, on the platform CI uses, with the whole suite running
rather than one test in isolation. Three separate variables, and each has hidden something:

- **Configuration.** .NET `Release`, a minified or bundled JS build, a Go binary with its release
  flags. The debug build is not the artifact.
- **Platform.** Linux in CI, whatever you develop on locally.
- **Concurrency.** The full suite, not one test alone.

**Caught:** a test that failed only in Release on Linux, which no run had ever performed because CI
built Release and tested Debug. The assembly consumers install had never had a test run against it.
The cause was a port race in a test double that released its port before rebinding it, and it was
invisible when that test ran alone.

For a bundled JavaScript package the same gap is sharper: tests run against source modules while
consumers get the bundle, so nothing has tested what ships unless something imports the built
output.

### Consume your own artifact the way a stranger would

Build the thing you publish, install it from a local source into an empty project, and use it.
Never test only the source tree.

**Justified by:** every test and demo in these repos consumes the library through a project
reference. Consumers do not. Static web assets, build targets and per-framework dependency groups
all resolve differently for a package, so a package can pack cleanly, pass every test, and be inert
for the first person who installs it, with nothing anywhere to say so.

| Stack | What that means |
|---|---|
| .NET | `dotnet pack` to a local feed, `dotnet new`, `dotnet add package --source`, build, assert the assets resolve |
| npm | `npm pack`, install the tarball into a scratch project, import it, run it. `npm publish --dry-run` lists files but proves nothing runs |
| Go | build the binary, or `go install` from a module proxy, then execute it |
| Container | run the built image, not the compose file you develop with |

The npm case has its own trap worth naming: the published tarball is decided by `files`, `.npmignore`
and the build output, none of which the repo working tree reflects. Installing the tarball is the
only way to see what a consumer actually gets.

### Exercise the deployed artifact before publishing

Deploy the artifact somewhere real, use it, and make the publish refuse if the deployed thing is not
the thing being published.

**Caught:** a backoffice publicly reachable on the playground, because nginx compares a location
prefix byte for byte while ASP.NET routing does not, so `/Umbraco/login` sailed past a block on
`/umbraco/`. No test host has a proxy in front of it.

Compare **identity, not version strings**. A version can be right while the deployed code is stale,
and today's `0.1.0` and yesterday's `0.1.0` are the same string and different builds. And compare
the **server** half, not only anything the client downloads: a server-only change leaves client
assets byte identical, and server-side is where most defects live. In .NET the assembly MVID works,
because it is regenerated on every compilation; a commit sha baked in at build time works anywhere.

**When there is no playground.** A CLI has no URL and a library has no deployment, so the gate is
not "is it live" but *does the built artifact do the thing when a person uses it*:

| Shape | The equivalent gate |
|---|---|
| CLI | run the built binary end to end against something real, not a mock |
| Library | the scratch-consumer step above, plus one test that uses it as documented in the README |
| Deployed app | the app **is** the playground. Deploy to a staging slot and assert its health before promoting |
| Anything with a promise | the row you wrote in *Gate the promise the project makes* |

The principle is the same in all four: **something that was built, not something that was compiled
in a test host, has to be observed doing the job.**

One thing to check whatever the shape: a 200 is not proof the endpoint exists. Umbraco answers 200
with the site's own HTML for any unrecognised path, so a marker endpoint returned 200 before it was
written. Assert the content type and the shape of the value, not the status.

### Look at the data, not the dashboard

Query the actual table before believing any number computed from it.

**Caught:** 35 of 40 rows in a live demo database were seeded or probe data, inflating the install
count roughly eightfold, and one real row counted a browser in fullscreen as an installed app.

### Mechanical guardrails, not review habits

Branch protection, a public API approval snapshot, required status checks, a secrets scan. Things
that hold when nobody is paying attention.

**Caught:** a public API change that would have made a bug fix a major version bump, flagged by the
approval snapshot with the versioning rule quoted back; and an unresolved review thread that
correctly blocked a merge while every check was green.

### Read the exit code, not the output

Judge a command by what it returned, not by what scrolled past. This sounds too obvious to write
down, which is exactly why it keeps happening.

**Caught:** a lint run reported as clean that was not. The command was piped through `grep` into
`head`, so the shell reported `head`'s exit status, the `|| echo failed` branch never fired, and
silence read as success. CI found the real failure on the next push.

Three shapes of the same mistake:

- **A pipeline returns its last stage.** `cmd | grep x | head` tells you about `head`. Use
  `set -o pipefail`, or capture `${PIPESTATUS[0]}`, or run the command on its own line and check `$?`.
- **A run that does nothing exits zero.** A test runner that discovers no test files, a linter given
  no matching paths, a loop whose input was empty. Assert the count, not the status.
- **Console output is formatted for a human, and the formatting changes.** If you must read a
  number out of a tool, read it from that tool's machine-readable output.

**Caught, by the guard written for the second bullet above.** The anti-vacuity check asserted the
test count by grepping the console reporter for `Test Files  1`. It passed locally and failed a CI
run in which all 24 tests passed, because the runner colours that output and a laptop pipe does not,
so ANSI escapes sat between the words. Reading `numTotalTests` from the JSON reporter is the same
check with nothing to break.

Worth sitting with: that was written in the same hour as this section, by someone who had just
finished describing the failure. Knowing the rule is not the same as following it, which is the
argument for gates over intentions.

### A declared requirement is not an enforced one

When a manifest says which runtime or platform it needs, something has to check that. Most package
managers do not.

**Caught:** a test library declaring `node >=22` installed into a project on Node 20. Every test
passed, because npm treats `engines` as advisory. A second package in the same batch declared the
same requirement and failed loudly on import, and the loud one is the lucky case. The quiet one had
green CI on an unsupported runtime, and Node 20 had been end of life for three months and was the
base image of the published container.

The general rule: **anything advisory will be ignored eventually, so read it yourself.** Cheap
version of this gate is a build step that diffs declared `engines` against the CI runtime.

### Sanitise by allowlist, and expect a second door

If untrusted text is rendered as markup, the first vector you close is not the only one.

**Caught:** a page rendering `CHANGELOG.md`, a file edited by pull request, on a static site with no
runtime in front of it. Raw HTML was dropped, which looked complete. `[text](javascript:...)` is
ordinary markdown, so it survived that and rendered as a live href, as did `data:text/html`. Found
by the review bot after the author had already satisfied himself.

Allowlist what is permitted rather than removing what is known bad, and resolve URLs rather than
matching their prefix. `JaVaScRiPt:` and a leading space are the same thing to `new URL`, and each
needs its own pattern otherwise.

### Outside contributors test the process, not the code

Opening a repository to contributors exercises paths no amount of solo work reaches, and most of
what it finds is in the process rather than the diff.

**Caught, in one week of a repository being open:**

- A contributor **refused a review instruction of mine** that would have made the host header
  authoritative behind `AllowedHosts: "*"`. He was right and I was wrong, and only an outside
  reviewer was positioned to say so.
- **Two issues filed for features that already existed**, spotted by a contributor who read the code
  rather than the issue. Both were mine, from grepping for library API names instead of the
  implementation.
- The **CLA gate blocked the dependency bot's own pull requests**, which nothing had ever exercised
  because no bot had opened one against a protected branch before.
- **Assigning a non-collaborator is impossible in the web UI** and works through the REST API once
  that person has commented, so an issue can sit unassigned looking like nobody wants it.

None of these are code defects and none would have surfaced from another solo month.

### Links and invites expire

A URL that worked when it was written is not a URL that works.

**Caught:** a chat invite in the README, the contributing guide, the issue template and twice on the
marketing site, set to expire four weeks out. All five would have gone dead on the same day, on the
one path a new contributor uses, with nothing to report it. Invite links default to expiring; the
non-expiring option is a deliberate setting.

Worth a periodic link check in CI on the files that onboard people. Note that a bare `curl` is not
enough for this class: the expiring invite returned `200` right up until it did not.

### Publishing is not releasing

Pushing a package is one step. If the repository does not also record what shipped, the project
looks abandoned from the outside no matter how active it is.

**Caught:** 67 versions on the package registry, four git tags, and a releases page showing a version
from many months earlier as *latest*, next to a changelog that was accurate and current. Nothing was
broken; the release job simply never tagged. The costs are real anyway: `git log v<last>..HEAD` does
not resolve, so *what has landed since we shipped* cannot be answered from the repository, and a
contributor whose work merged has nothing that tells them it reached users.

---

## Say what you actually measured

The most common failure is not broken code. It is a true-looking claim nobody can verify. It has
appeared on four unrelated surfaces:

- Documentation describing a provider that was never implemented.
- A dashboard reading *12 installed*, when uninstall is not observable on any platform and the real
  meaning is *12 have ever installed*.
- A NuGet download count that is almost entirely mirrors and crawlers, with no NuGet client anywhere
  in the breakdown.
- A CI check reporting green while its reviewer was rate limited and had read nothing.

So: **if you cannot verify it, the label says what was actually measured.** Not *12 installed* but
*9 of 12 installs seen in the last 30 days*, with the window in the label rather than a tooltip. A
number whose definition lives in a hover is a number people quote wrongly.

The same applies to your own reporting. If tests fail, say so with the output. If a step was
skipped, say it was skipped. A green tick you did not verify is not evidence.

## Read a signal before trusting it

| Signal | Looks like | Actually |
|---|---|---|
| Cancelled CI job | a failure in `gh pr checks` | a superseded run. Identical durations across jobs is the tell; `gh api .../jobs` says `cancelled` |
| Green review bot | reviewed and approved | may mean rate limited and read nothing. Open the comment |
| Marketplace 404 | rejected | usually scan latency. Re-check after the next sync before concluding |
| A piped command succeeding | the command worked | the **last stage** worked. `cmd \| grep x \| head` reports `head` |
| Green tests on a new dependency | it is compatible | `engines` is advisory to npm. It may be running on a runtime it declares unsupported |
| A vulnerability alert count | current exposure | may predate the fix. Compare each advisory's patched version against what is actually resolved, and check the alert's `updated_at` against the merge |
| A `200` from a link check | the link is good | for an invite or a token URL, it is good **today**. Check the expiry, not the status |

---

## Setting up a new project

Done once, at the start, before the first feature. All of it is cheaper now than retrofitted.

- [ ] `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`. A repo whose README claims MIT
      with no licence file cannot legally be used or forked.
- [ ] Branch protection on the default branch: pull request required, no force push, no deletion,
      conversations resolved. Approvals at **zero** while you are the only maintainer, or you lock
      yourself out.
- [ ] CI on pull requests, **in Release**, across every version you claim to support.
- [ ] A required status check wired to a job that actually runs on pull requests. Protection with
      no check is a turnstile.
- [ ] A machine-checked record of the public surface, with the versioning rule in its failure
      message: `PublicApiGenerator` for .NET, `api-extractor` or a committed `.d.ts` for npm,
      `apidiff` for Go. Anything that makes an accidental breaking change fail a build rather than
      surprise a consumer.
- [ ] An anti-vacuity check. A run that discovers no tests exits zero, so assert the count.
- [ ] A secrets scan, with no path exemption on the rules that matter.
- [ ] A playground deployment, and a publish workflow that refuses to publish without it. Check the
      `needs:` graph, not the intent: the publish job must depend on the job that observed a running
      build, and it is easy to wire these the wrong way round and never notice.
- [ ] Release tagging. A tag and a release per published version, with the changelog section as the
      body, or the repository cannot say what shipped and the releases page misrepresents the project.
- [ ] Issue and pull request templates that ask for the failing case, not the intention.
- [ ] `set -o pipefail` in every multi-stage shell step, so a pipeline reports the failing stage
      rather than its last one.
- [ ] A link check over the files that onboard people, including expiry for invites and tokens.

---

## Applied to these repos, 17 August 2026

Run against six projects across three languages, to check it says something different about each
rather than the same thing about all of them. It does:

| | Missing |
|---|---|
| **Verdict** (.NET) | nothing on this list. Eight API snapshots, the fullest coverage here |
| **dopaminejs** (npm) | nothing on this list |
| **Mapsicle** (.NET) | a public API gate |
| **Carom** (.NET) | a public API gate, and it has eleven open issues inviting contributors |
| **Talaan** (.NET) | a changelog, a public API gate |
| **BaryoVM** (Go) | a changelog, an `apidiff` gate |
| **barakoCMS** (.NET + npm) | a public API gate, release tagging, and the publish ordering below |

Two things that reading it alone would not have surfaced. **Carom is the most exposed**: it invites
contributors into a library with no machine-checked public surface, so the first well-meaning pull
request can break consumers with every check green. And **a missing changelog is not paperwork** on
a published package: without one, a consumer deciding whether to upgrade has only a diff.

**barakoCMS publishes in the wrong order**, which is the one worth fixing first anywhere it appears.
Its release job graph is `test` → `publish` → `deploy-playground`: packages and public images go out,
and only then does anything get deployed and looked at. Phase 6 above says the opposite, and the
reason is asymmetry. A bad deploy is rolled back in a minute. A bad publish is permanent. Package
registries do not delete, they unlist, and anyone who already resolved the version keeps it. **Put
the irreversible step last.**

Worth checking in any pipeline: draw the `needs:` graph and find where the irreversible job sits. If
anything that touches the outside world runs before the thing that observes a running build, the
ordering is wrong regardless of how thorough the tests are.

## What this costs, and when to skip it

The full process suits something that will be published, installed by strangers, or maintained by
people you have not met. It is disproportionate for a spike, a throwaway script, or a one-line fix.

Three parts are never worth skipping, at any size, because each caught something real:

1. Run the tests in the configuration you ship.
2. Break a new test to prove it can fail.
3. Look at the running system before saying it works.

---

## Keeping this document honest

This file is a record of things that actually went wrong, not a standard copied from somewhere. That
only stays true if it is updated at the moment something is learned, which is also the moment it is
least convenient.

**When something gets through, add the gate that would have stopped it, and cite what it caught.**
One short section: what the gate is, and the specific failure in a sentence or two. If you cannot
name what it caught, it does not go in. A gate with no incident behind it is ceremony, and the
opening of this document says to delete those rather than keep them for the look of the thing.

Three prompts worth answering out loud at the end of a piece of work, because each one has produced
a section above:

- **What did I believe that turned out not to be true?** Not what broke. What I was confident about.
- **What went green that should have gone red?** A silent pass is worth more attention than a
  failure, because the failure announced itself.
- **Who or what caught this, and would it have been caught without them?** If the answer is a person
  rather than a mechanism, the mechanism is missing.

If a session ends with something learned and nothing added here, the learning is gone by next week.
