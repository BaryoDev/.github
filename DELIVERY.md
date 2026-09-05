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

**And check the mutation, not just the test.** Proving an allocation gate could fail meant making
the code allocate. Boxing a `bool` was the obvious way, the gate stayed green, and for a moment that
looked like a broken gate. The JIT had elided the box, so nothing allocated and the gate was right.
`GC.KeepAlive(new object())` turned it red immediately. A mutation the compiler optimises away
proves nothing in either direction, which is the same trap one level up.

### A file on your disk is not a file in the repository

Run the checks against a fresh checkout, not your working tree. Anything that reads files from the
repo, a link checker, a docs test, a template renderer, is checking your machine unless CI runs it.

**Caught:** eight package guides were written, the docs index linked all eight, and every test
passed locally. `.gitignore` had an unanchored `packages/` rule meant for a NuGet folder, which also
matched `docs/packages/`, so `git add -A` skipped all eight without a word and the branch shipped a
documentation index pointing at nothing. The link test passed on the laptop because the files were
there. It failed on the first CI run, on a clean clone, which is the only place the difference is
visible.

**`git add -A` is silent about what it ignored.** That silence is the failure, not the rule.

### Absence of output is not absence of the thing

A diagnostic step that prints nothing looks the same as a diagnostic step
reporting nothing is there. If a check exists to answer a question, make it
assert the answer rather than print material for a human to read.

**Caught:** a CI matrix leg was added to run the suite on .NET 10, with a comment
explaining that installing only that SDK left the net8.0 assemblies no 8.0
runtime to load, so they would roll forward. A step printed `dotnet --info` for
evidence. Its `sed` pattern was case-sensitive, matched nothing, and printed only
a version header. Grepping that empty output for a .NET 8 runtime found none,
which read as confirmation and went into the pull request as verified.

The hosted image ships .NET 8, 9 and 10, `setup-dotnet` adds to them rather than
replacing them, and roll-forward never engages when an exact match is present.
Both legs had been running the net8.0 assets on .NET 8.0.30. The second leg
tested nothing the first did not, which is the exact failure the matrix was added
to avoid.

Replacing the print with an assertion caught it on the first run. The real fix was
to multi-target the test projects, because targeting the framework is the only
thing that moves the runtime.

**A step whose output nobody fails on is a comment.**

### Assert the middle, not just the edges

A test that checks the first and last element of a collection, or its count, will pass while
everything between them is destroyed.

**Caught:** a pooled buffer was returned to `ArrayPool` with `clearArray: true` and then copied out
of, one line too late, so every item collected before the first buffer doubling came back blank: 16
of 17, 512 of 2000. Two tests covered that code path. One asserted the count and the final element,
and the final element is written after the loss. The other used a collection type that took a
different branch entirely. Both were green. Asserting every index, at sizes that straddle each
doubling, fails immediately.

**Count is not content.**

### A completeness check must derive its subject, and key on what distinguishes a row

A test that answers "did we miss one" is only worth having if it can say no. Two ways it cannot,
and both look identical to a working one:

**It reads a list somebody maintains.** Then it answers "no" by construction, because the list and
the thing it describes are updated by the same hand at the same moment, or not at all.

**Its key is coarser than the rows.** A check keyed on path, over rows keyed on verb and path,
passes when a verb goes missing from a path that still has another.

**Caught five times in one day, on the same migration:** a fixture seeding a hand-written list of
modules, stale within hours of being written when a module gained a capability; two test-side lists
of the same shape, one of which stayed green while the thing it checked did nothing at all; a route
inventory covering 32 of 35 while its doc comment claimed all; and a coverage test comparing paths
while its rows distinguished verbs. Three of the five were written to replace an earlier list of
exactly the same kind.

Derive the set from the running system, key on everything that tells two entries apart, and assert a
floor: a reflection query that matches nothing fails the same way a correct one passes.

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

### An argued consequence is an issue, not a PR

Before opening a PR on someone else's project, the body has to answer the maintainer's first
question, "what was the use case that got you here", with something that ran. If the strongest
honest sentence about the consequence is "argued rather than demonstrated", file it as an issue and
hand the design fork to the maintainer. The check is mechanical: read your own PR body for that
admission before you open it.

**Caught, by the maintainer rather than a mechanism, which is the point:** Marten #5302 fixed a
real silent no-op, transaction participants accepted and never invoked under an ambient
transaction, with an honest failing test on master. Closed the same day: "I do not want to support
ambient transactions inside of projections, full stop." The PR body already contained the
admission, "argued rather than demonstrated here"; nothing read it before the PR went out. The fix
looked mechanical because three sibling lifetimes did it right, but whether the combination should
be supported at all was a design fork, and design forks belong in issues.

### Look at the data, not the dashboard

Query the actual table before believing any number computed from it.

**Caught:** 35 of 40 rows in a live demo database were seeded or probe data, inflating the install
count roughly eightfold, and one real row counted a browser in fullscreen as an installed app.

### Read the board before you write code

Check open pull requests and issues on a repo before starting work on it. On anything that invites
contributions, do it every time.

**Caught, badly and late:** a maintainer filed an issue and built a fix for a problem a first-time
contributor had already solved in an open pull request a day earlier. The duplicate was noticed by
accident during an unrelated sweep, not by any check, and only because somebody thought to ask what
else was outstanding.

The cost lands on the contributor, not on you. Having your first contribution silently duplicated by
the person you contributed to is the most discouraging outcome available, and it is invisible from
the maintainer's side: the work still gets done, the issue still closes, and nothing looks wrong.

Two mechanisms, because the habit alone did not hold:

- **Watch your own repositories.** Guardrails decide what may merge; none of them tell you anything
  arrived. Four pull requests sat for a day and a half on a repo whose owner was not subscribed to
  it, because org repos do not notify their owner by default.
- **Assign yourself, or comment, before starting.** The `/take` convention exists for contributors
  and applies to maintainers for the same reason.

### A contributor's licence grant is not a process rule

Branch protection can be overridden by an admin when the situation warrants it. A CLA check cannot,
and the difference is worth being explicit about because both appear as a red check on a pull
request.

Protection rules govern process on your own repository. A CLA is the **licence grant** that lets you
redistribute someone else's code under your terms. Overriding it does not create the grant; it only
removes the thing that was checking for one, and the package still ships their work without it.

**Encountered:** three pull requests blocked as unsigned from a contributor who *had* signed. The
signature covered the whole organisation. It could not attach because the commits carried an email
with no numeric ID prefix, so GitHub resolved them to no account at all and the CLA service had no
identity to match. A fourth pull request from the same person, using the ID-prefixed address, passed
immediately.

So read an unsigned CLA as a question about **identity** before assuming refusal, and never as
something to wave through:

- `username@users.noreply.github.com` resolves to nobody. `12345678+username@users.noreply.github.com` resolves to the account.
- A commit authored by a tool identity, `Agent Core <agent@agent-core.local>` in this case, can never
  be covered by anyone's signature, because a CLA is an agreement with a person. Set the tool's git
  identity to a real contributor or every pull request it produces is permanently unmergeable.

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

### A search that edits a file has to be told where to look

A script that finds its place in a file by matching a landmark will take the first match. The first
match is not necessarily the one meant, and nothing about the exit code says which one it took.

**Caught:** the changelog assembler filing a release's entries into the previous release's notes. It
looked for its `### Fixed` heading with an unscoped search, and a release empties the Unreleased
section, headings included, so the first match in the file belonged to the version that had just
shipped. Seven entries, two of them security, went into the notes of a release that was already
published, where the next release body would never read them. The script printed
`Assembled 5 into Fixed` and exited zero.

The intent was in the code, in words: the error it raises when the heading is missing says "in the
unreleased section". Nobody had written the part that made it so. A comment describing the scope is
not a scope.

Caught by reading the diff rather than by any gate, which is the answer that says a gate was
missing. There is one now: searches are scoped to the Unreleased section, a missing heading is
created in place, and a fixture test asserts where an entry lands. It was watched failing before it
was trusted, 0 of 6 against the old logic and 6 of 6 after.

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

### A failure with no commit behind it needs somewhere to go

A gate that only fails on a pull request is watched, because somebody is waiting on that pull
request. A gate that can fail on its own, with no commit behind it, is not watched by anybody.

Dependency auditing is the obvious one. `NuGetAuditMode=all` with `TreatWarningsAsErrors=true`
turns any newly published advisory against any transitive dependency into a red build, days or
weeks after the last commit. So does an npm advisory, a base image moving, or a runtime reaching
end of life.

**Caught:** Mapsicle's audit job failed for at least three days on five advisories. Every other job
was green: build and test passed on both operating systems, formatting passed, the
core-stays-dependency-free check passed. Nothing announced the failure, because nothing was
waiting on it. It surfaced only when the org's repositories were listed by download count for an
unrelated reason, and Mapsicle turned out to have more downloads than every other package in the
org combined.

Two things this cost, and both are worth naming:

- **Three days of a red default branch** on the most-used package, which is what a stranger sees.
- **A wrong conclusion, briefly.** The red build was read as "users are on a broken package". They
  were not: all five advisories reached test projects only and no shipped package was affected.
  A red build says something failed, not what is exposed. Check which projects before saying who
  is at risk.

The same week, two of three other red repositories in the org had no commit behind them either.
The world moved; the code did not.

**What to do about it:** give these jobs their own schedule and their own notification, rather than
leaving them to be noticed on the next pull request. If a job can fail without anyone pushing, it
needs a route to a human that does not depend on anyone pushing.

### A green check proves something about where it ran

A check runs somewhere. That somewhere has to be the place the property actually holds, and the
default is usually not it. Both halves of this were found in one afternoon, on the same repository,
and neither announced itself.

**Caught:** a 4KB request body cap that nothing enforced in the suite. `[RequestSizeLimit]` does not
reject anything itself, it sets `IHttpMaxRequestBodySizeFeature`, and Kestrel is what reads it. The
integration suite runs on `WebApplicationFactory`, which serves over TestServer, and TestServer does
not implement that feature. So the attribute was inert there and an 8KB body came back `202`. Three
documents stated the cap. Any test written for it in that suite would have passed while asserting
nothing. The fix was not a better assertion, it was moving the test to the suite that starts the
real host in a child process.

**Caught, an hour later:** a mutation check that could not see the mutation. A secret-scanning
allowlist had been widened, and widening one far enough to disable the rule looks identical to
widening it correctly, so the rule was tested by putting a real-looking password in the file. The
scan came back clean and the allowlist looked safe. `gitleaks detect` scans commits. The password
was in the working tree, uncommitted, and was never examined. `--no-git` is the flag that scans
files, and with it the rule fired immediately.

The shape both times: the runner was real, the command exited zero, and the thing under test was
outside the scope the runner was looking at. Worth asking before trusting any green:

- **Does this host implement the thing being asserted?** Test hosts, in-memory servers and fakes
  routinely omit features the production host enforces. Limits, timeouts, TLS redirection and
  middleware ordering are the usual casualties.
- **What is this tool's unit of work?** Commits, staged changes, the filesystem, one package, the
  whole solution. A scanner pointed at history says nothing about your disk.
- **Did the check see my change at all?** If deliberately breaking the thing leaves the check green,
  the check was never reading it, whatever else it was doing.

The third question is the cheap one and it subsumes the others. It is also the one skipped most
often, because by then the check is already green and the work feels done.

### Publishing is not releasing

Pushing a package is one step. If the repository does not also record what shipped, the project
looks abandoned from the outside no matter how active it is.

**Caught:** 67 versions on the package registry, four git tags, and a releases page showing a version
from many months earlier as *latest*, next to a changelog that was accurate and current. Nothing was
broken; the release job simply never tagged. The costs are real anyway: `git log v<last>..HEAD` does
not resolve, so *what has landed since we shipped* cannot be answered from the repository, and a
contributor whose work merged has nothing that tells them it reached users.

### A field added to a config is not a field that arrives

When a call site takes a configuration object and unpacks selected fields by hand to pass onward,
adding a field to that object does nothing on that path. The compiler is content, the tests are
content, and the new setting is silently ignored wherever the unpacking happens. The fix is to pass
the object through, not to add the field in every place that takes it apart.

**Caught:** in Carom 2.0, by the review bot, in the same release whose headline fix was that a
one-state-per-key rule existed in three copies and was fully enforced in one. That release added a
configurable retry delay cap and made the synchronous entry point throw on a timeout it cannot
honour. Three extension packages accepted the config struct and unpacked chosen fields by hand, so
both new fields were dropped: a 50 ms cap took 5,615 ms through an extension against 170 ms through
the core, and a timeout that threw on the core path was accepted in silence on all three extension
paths. 948 tests were green.

The uncomfortable part is that the release existed to fix exactly this shape of defect and
reproduced it within itself. A rule applied in one place and not the others is not a bug you fix
once; it is a shape you keep making until the structure stops allowing it. Passing the whole object
was the fix, because it makes the next field impossible to drop.

### A config file in the repo is a copy, not the deployment

A deploy step that installs config from the repo overwrites whatever is on the server, including
changes the repo has never seen. No check in the repo can detect an omission relative to a file it
does not have. Diff the installed file against the repo copy before installing it, fail on any
difference, and fold the difference in rather than flattening it.

Fail closed, in the deploy step itself, naming both paths:

```bash
# baryoweb: deploy/nginx-baryo-web-locations.conf installs as
# /etc/nginx/snippets/baryo-web-locations.conf
diff -u /etc/nginx/snippets/baryo-web-locations.conf deploy/nginx-baryo-web-locations.conf || {
  echo "installed config differs from the repo copy; reconcile before installing" >&2
  exit 1
}
```

A difference is not noise to clear on the way past. It is work someone did on the server that no
review has seen, and the deploy is the moment it gets destroyed.

**Caught:** by a question, which is the problem. baryo.dev's nginx snippet in git was two changes
behind `/etc/nginx/snippets/`. The box already answered 410 on the retired barakoCMS paths, and it
included `baryo-blog-redirects.conf`: 25 per-post redirects generated from the pre-decommission
backup when the blog was retired, so that each post kept a working URL to its Medium original or to
barakocms.com. Git had no copy of that file. The server held the only one. Installing the repo
version would have dropped the include and 404'd every retired blog URL, and un-retired a
`/feed.xml` that no longer exists.

`nginx -t` passed on the repo version. So did a route table run against a real nginx serving the
real build: twelve paths, every one correct, including the case-sensitivity split between
`/barakocms` and `/barakoCMS`. Everything was green, because every check tested what the file said
and nothing tested what the file had stopped saying.

It surfaced only because the deploy was blocked on a missing SSH key, and a question about how a
sibling repo authenticates led to noticing that the deploy target was the machine the work was
already happening on. That made a diff possible. Nothing else in the session would have asked for
one, because the repo copy looked complete and every gate agreed.

### Queueing work is not running it

A test whose point is to create a condition must wait for that condition to exist before asserting.
Queueing background work and proceeding immediately tests whatever the scheduler happened to do.

**Caught:** a timeout test queued `ProcessorCount * 4` blocking work items to saturate the thread
pool, then went straight to its assertions. Nothing waited for a single worker to start, so the
assertions usually ran against an idle pool. It passed on every run, having never once created the
condition it was written to create.

Making each worker signal a countdown and waiting for all of them turned it red on the first run.
What it exposed was not the intermittent failure it was written to catch: under real saturation the
pool cancels the queued task before the action starts, and the strategy surfaced a cancellation
exception where its contract promised a timeout. A wrong exception type had been sitting behind a
green test, invisible because the test's own precondition was never checked.

A test with an unasserted precondition is a test of nothing, and it is worse than no test, because
it occupies the space where the real one would have gone.

### A step that fails hides every step behind it

Lint, typecheck and tests as sequential steps in one job means the first failure decides what
anybody learns. The steps after it do not report, and their state is not unknown-and-noticed, it is
unknown-and-invisible, because the job already has a red mark against it and the red mark has a
cause. Give the later steps a condition, or give them their own jobs.

**Caught:** barakoBrew lost its entire repository setup to this, over a one-line ignore, the day
after the setup was opened.

`npm run lint` passes no path, so ESLint read the whole tree, and the config never excluded `docs/`.
The design handoff ships vendored single-file prototypes whose bundled React still calls
`ReactDOM.render` and assigns to `module`. Two errors, exit 1, in files that say nothing about the
codebase. Typecheck and Unit tests were declared after Lint with no condition, so in all six runs
they read:

```text
Lint        failure
Typecheck   skipped
Unit tests  skipped
```

The setup pull request was closed the next day and not revived, which left the repository with no
`.github/` at all: no CI, no CodeQL, no Dependabot, no templates, no CODEOWNERS. Not one check has
run on master since it was created.

What the concealment cost, found four days later by running the two skipped commands by hand:
master's unit suite does not pass. One test read the API's C# enum out of a sibling checkout, to
hold the console's status list against the server's, and the split moved that file one directory
deeper. It broke at the split and nothing has executed it since. So the gate that would have caught
a status diverging between the two halves of one product was itself broken, quietly, from the
moment the two halves existed.

Two further things worth naming from the same incident. The Actions tab listed CI and CodeQL the
whole time, linking to `blob/master/.github/workflows/`, because GitHub keeps a workflow
registration after the branch that introduced it is abandoned. Registration is not execution, and
the tab reads identically either way. And the lint scope was the real defect: a gate pointed at
vendored reference material fails for reasons that say nothing about the code, and the second time
it does that, somebody turns the gate off rather than the scope down.

### Every gate here reads text, and half of what an agent produces is not text

The house style scan, the review bot, the whole-branch review and the grep-for-the-claim rule all
read a diff. An image is not a diff. Neither is a generated document, a lock file or a fixture.
Whatever an agent makes that a reviewer cannot read is a blind spot by construction rather than by
oversight, and it is invisible in the way that matters most, because everything around it is green.

The specific thing to look for is attribution: agents that generate images embed a signed manifest
naming the tool that made them. C2PA in a PNG is an optional named chunk, in a WebP a chunk, in a
JPEG a segment near the front, in an SVG a metadata element. It travels with the file into whatever
the build packs it into.

**Caught, twice, in projects that had every other check passing.**

A change swapping the icons on fourteen published packages came through clean. Each exported image
carried about five and a half kilobytes of signed provenance manifest, and the build packed those
images into every package. It was one merge from being published under a person's name on a public
registry. That incident is written up as section 9 of
[the lean agent method](https://github.com/arnelirobles/lean-agent-method), which is where the
scanner below comes from.

Then again here, four days later, in barakoBrew. Nine regenerated design screenshots, 5,758 bytes of
C2PA manifest each. Six CI jobs were green over them, including an axe pass and a full unmocked run
of the console against a real API. Nothing in that suite could see inside a PNG. It was found by
pointing a byte-level scanner at the tree, and fixed before the pull request merged only because
that pull request happened to be blocked rather than queued.

Three rules come out of it.

**Gate the bytes.** Parse each container and fail on anything that is not picture data. Detection is
cheap: `strings file.png | grep -i c2pa` tells you today whether you have this, and most people who
generate assets do. Treat an unrecognised chunk as a finding too, so a provenance format that does
not exist yet still trips it.

**Filter, do not re-encode.** Running everything through an image tool with a strip flag works and
rewrites every pixel, which changes the file hash. If any of your evidence is a hash, you have just
invalidated it and you will not notice. Drop the optional chunks and leave the compressed stream
alone, then prove it: hash the image data before and after and refuse the write if they differ.

**Scan the whole repository, not the diff.** The first run of this check found a file carrying a
screenshot's camera metadata since the day it was committed, months earlier. That is true of every
check scoped to a diff.

One process note that nearly cost the fix: a branch in a merge queue cannot be pushed to. Know how
to pull one out before you need to, because the window is however long the queue takes.

### The registry reads your docs

Before publishing, defang executable-looking payload strings in every file the package tarball
ships (README, CHANGELOG). Documentation of what your security layer *rejects* must not itself be a
working payload: `'; DELETE FROM users --` documents the same attack class as `'; DROP TABLE users
--` without pattern-matching a scanner. When a publish fails with a generic policy error, bisect
with the cheapest oracle available before believing any hypothesis.

**Caught:** rnxORM 2.2.0 was unpublishable for a night — npm's publish-time content scanner
rejected the tarball because the README and CHANGELOG documented SQL-injection payloads
(`DROP TABLE` strings) as examples of input the ORM now rejects. The 403 was generic
("forbidden by your security policy"), identical across OIDC trusted publishing, staged
publishing, and owner-interactive publishing, which produced four plausible wrong diagnoses in
sequence: trusted-publisher misconfiguration, 2FA publishing access, a staged-publish mandate, and
a blocked package name — the last one far enough to rename the package before the truth surfaced.
The tell that broke it open: a trivial probe package under the same account sailed to a normal OTP
prompt. From there, bisection with an EOTP-vs-403 oracle (a publish stopped at the OTP prompt has
passed policy without publishing anything) pinned the trigger to the payload strings in two
minutes. Nothing in any error message, debug log, or status page named the real cause.

A scanner that cannot tell documentation from payload is still the gate you must pass. Design the
docs for it, and when a generic rejection resists three explanations, stop theorizing and bisect.

### A number typed into a page is a claim nothing checks

Any figure a page states about the project (a count of packages, a version, a download total) is
read from the thing that owns it at build time, never typed into the markup. A script fails the
build on a literal that looks like one.

**Caught:** the barakocms.com design said "thirteen modules, all at 4.0.0". The repository had
fourteen module projects. NuGet had thirteen, but a different thirteen: the design named
`BarakoCMS.Email.Smtp`, which has never been published, and omitted `BarakoCMS.Files.S3`, which
has. The published core was `3.21.0` and every module was on `0.x`. Three wrong claims from one
habit, in a document whose own stated rule was that every claim is checkable or cut.

Nothing was going to catch this. The export check asserted `grep -q "barakocms-module"` against the
built page, which passes whether the page says thirteen or thirty. A page of wrong numbers built
cleanly, passed every gate, and would have shipped. A person reading nuget.org caught it, which
means there was no mechanism.

Once the numbers came from the fetch, the same rendering also stopped being able to go stale: a
module published tomorrow appears, and one that exists only in the repository does not.

**The gate has to fail on the shape the code actually has.** The first version of this script
required the package id and the version number to appear on the same line. The card that produced
the original wrong claim puts them on different lines, so the exact markup the gate existed to
reject sailed through it. It was reported as verified after only the other half of it had been
exercised. Rewritten to match any version inside JSX text, it immediately found four more typed
claims nobody had noticed, in a roadmap section that had never been looked at.

### A fallback that renders identically to the real thing

When a build-time fetch is allowed to fail without failing the build, the page it produces must say
that it is degraded. Otherwise the fallback is a silent wrong answer with a green build behind it.

**Caught twice on the same site, one of them in production.** The module list falls back to a
bundled snapshot when NuGet is unreachable, which is correct: an outage should not stop a deploy.
The rewritten page dropped the `live` flag the previous page had used, so an outage would have
rendered frozen version numbers formatted exactly like current ones, with nothing saying so.

The second one actually shipped. The changelog credits contributors from the commits API, and
GitHub allows sixty unauthenticated requests an hour per IP. That budget was spent, the build
warned and fell back as designed, and the site went live with every contributor missing. The
warning was in the log. Nobody read the log, because the build was green and the deploy succeeded.

**A warning is not a gate.** Either the degraded state is visible on the page, or the build fails,
or nobody will ever know which one they are looking at. Passing the token that lifts the limit is
the fix for the cause; saying "showing a cached list" on the page is the fix for the class.

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
Its release job graph runs `test`, then `publish`, then `deploy-playground`: packages and public images go out,
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
