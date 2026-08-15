# Every change needs a test that fails without it

Every BaryoDev repo says a version of that sentence in its CONTRIBUTING. This page is the worked
version: what a passing test that proves nothing actually looks like, next to the one that replaced
it, with the production change that separates them.

Every example here is real. Each one comes from a merged pull request or a shipped commit in
`BaryoDev/umbraco-pwa` or `BaryoDev.Umbraco.ReadAloud`, and each one had a maintainer or a reviewer
argue about it before it landed.

## Why the rule exists in this form

These projects are built to be contributed to by people I have never met, working faster than I can
review line by line. That works. What it depends on is that a change arrives with evidence attached,
because the alternative is that I re-derive the evidence myself for every pull request, which does
not scale and is a worse use of your time as well as mine.

The rule is not about volume of tests. A repo can have a green suite of two hundred tests and no
coverage of the thing you just changed. The rule is about one specific property: somewhere in the
diff there is a test that goes red if the production change is removed.

## The question

Before you open a pull request, ask yourself this about each test you added:

> **Name the production change that would make this test fail.**

Not "what does this test cover". Name the edit. A deleted line, a reverted condition, a method body
replaced with `return Task.CompletedTask;`. If you can name it in one sentence, the test is doing
work. If you find yourself describing the feature instead of the edit, that is the signal.

You do not have to guess. Make the edit, run the test, watch it fail, put the code back. That takes
under a minute and it is the only thing that actually answers the question. In this codebase we call
that a mutation, and pull requests that include the failure output get reviewed faster, because the
part I would otherwise have to check myself is already done.

If the honest answer is "none", say so in the pull request description. That is useful information
and it is not held against you. There is a section at the end about the cases where it is the
correct answer.

---

## Example 1: the test asserts the wiring, not the behaviour

This is the most common shape, by a wide margin, and it is the one worth reading if you read only
one.

`umbraco-pwa` PR #17 added a startup readiness check: after Umbraco boots, evaluate whether the site
is installable as a PWA, and log a warning if it is not. Good change, real gap, careful integration
into the composer. It came with two tests.

The tests resolved the readiness service from DI and asserted it was not null, then asserted the
handler type was registered. From the review:

> Replace the body of `HandleAsync` with `return Task.CompletedTask;` and both tests still pass.

That is the whole finding. The feature could have been entirely absent and the suite stayed green.
Both tests were about the container, and the container was never the risky part.

It is worth being precise about what went wrong, because "add more tests" is the wrong lesson. The
tests were not lazy. They tested the part that is easy to reach from a test: registration is a
synchronous lookup with an obvious assertion. The behaviour, "a warning appears in the log", needs a
captured logger and a booted fixture, which is more setup. The gap opened where the effort was.

There was a second consequence, and it is the reason the rule pays for itself. The feature had a
defect that a behaviour test would have caught on the first run: the warning fired on the default
state of a fresh install, not on a regression, so every `dotnet run` and every app pool recycle
logged it until the owner finished configuring the site. Running the test site's own boot produced
this with nothing changed in the fixture:

```
[WRN] PWA readiness check failed: Start URL has content. Start URL is the site root,
but nothing is published, so the installed app opens on Umbraco's default page.
```

A test that captured the logger and asserted against the default fixture would have gone red
immediately. The registration tests could not see it, because they never ran the handler.

**After.** The contributor replaced both with tests that assert the two things the change actually
does: nothing is logged at warning level in the default state, and the state is persisted so the
next boot has a baseline to compare against.

```csharp
[Fact]
public async Task Default_unconfigured_site_establishes_baseline_without_warning()
{
    // ... resolve real services from the booted fixture, with a capturing logger
    keyValueService.SetValue(PwaOneShotCheckHandler.ReadinessStateKey, string.Empty);

    var handler = new PwaOneShotCheckHandler(
        readinessService, runtimeState, keyValueService, logger);

    await handler.HandleAsync(
        new UmbracoApplicationStartedNotification(false), CancellationToken.None);

    logger.Entries.ShouldNotContain(entry => entry.Level == LogLevel.Warning);

    keyValueService
        .GetValue(PwaOneShotCheckHandler.ReadinessStateKey)
        .ShouldBe(bool.FalseString);
}
```

with a sibling test that seeds `bool.TrueString` as the previous state, runs the same handler, and
asserts a warning **is** logged. Between them: gut the handler and one of the two goes red.

Name the production change that would make it fail: `return Task.CompletedTask;` in `HandleAsync`.
That is the sentence that was missing from the first version.

## Example 2: the test cannot fail, because the fixture makes both cases identical

The `read-aloud` package clamps the requested voice to the site's allow-list. `?voice=` comes from
an anonymous caller, so a voice outside the list has to be replaced by the default. There are two
routes, audio and timings, and both have to clamp.

The test for the timings route seeded a cached entry for the alternative voice, requested it with an
empty allow-list, and asserted:

```csharp
// The default voice's cached entry carries one boundary for "quick"; the alternative's
// carries the same, so the check that matters is that it resolved at all rather than
// reaching for a voice the site never listed.
result.ShouldBeOfType<JsonResult>();
```

Read the comment. It says out loud that both cached entries carry the same word. So the clamp could
be deleted, the route could serve the alternative voice's timings, and the assertion would still
hold, because both answers look the same coming out. The test asserted the response was a
`JsonResult` and nothing about which voice produced it.

The fix was in the fixture, not the assertion. Seed distinct text per voice, then assert on the
content:

```csharp
// Timings are per voice, so the route that serves them has to clamp the voice the same way
// the audio route does. The two cached entries carry different words, which is what lets
// this test tell which one was read: seeding both with the same word made it unfailable.
await _site.SeedAudioAsync(
    UmbracoSiteFixture.BodyHtml, SeededAlternativeAudio, AllowedAlternative,
    AlternativeBoundaryText);

var options = Options();
options.AllowedVoices = [];

var result = await TimingsAsync(options, _site.PublishedNodeKey, AllowedAlternative);

var boundaries = result.ShouldBeOfType<JsonResult>()
    .Value.ShouldBeAssignableTo<IReadOnlyList<WordBoundary>>();

boundaries!.ShouldHaveSingleItem().Text.ShouldBe(UmbracoSiteFixture.DefaultBoundaryText,
    $"an empty allow-list means the default voice, so the timings must not be the "
    + $"'{AlternativeBoundaryText}' entry cached against {AllowedAlternative}");
```

Revert the clamp now and the run says:

```
should be "quick" but was "alternative"
```

Which is exactly the thing that matters: the timings of a voice the site never allowed, served over
the route whose job is to clamp it. Before the fixture change, the same revert produced a green run.

The general shape: **if your fixture makes the correct and incorrect answers look the same, no
assertion can save the test.** Vary the input along the axis the code is supposed to care about.

## Example 3: the test can pass for the wrong reason under load

`CoalescingAudioSource` exists so that two hundred readers pressing Listen on a new article open one
WebSocket rather than two hundred. The test made two hundred concurrent calls and asserted the
engine was called once. The engine double was kept busy with a fixed delay:

```csharp
var engine = new CountingEngine { Delay = TimeSpan.FromMilliseconds(150) };
var source = new CoalescingAudioSource(engine, new MemoryCache(), NullLogger<CoalescingAudioSource>.Instance);

await Task.WhenAll(Enumerable.Range(0, 200).Select(_ => source.GetOrCreateAsync(Request())));

engine.Calls.ShouldBe(1);
```

This one is subtler, because the mutation does make it fail, most of the time, on a healthy machine.
The problem is the other times. Under thread-pool starvation the two hundred callers can serialise:
the first completes, writes to the cache, and every caller after it resolves from a cache hit
without ever reaching the locking logic. `engine.Calls` is 1 and the assertion passes with the
coalescing entirely broken.

A test that only fails when the CI runner happens to be idle is not a flaky test to be retried, it
is a test that is not doing its job on the runs where it matters.

The fix is to stop hoping a delay outlasts the scheduler and hold the window open deliberately:

```csharp
var gate = new TaskCompletionSource<bool>();
var engine = new CountingEngine { Gate = gate };
var source = new CoalescingAudioSource(engine, new MemoryCache(), NullLogger<CoalescingAudioSource>.Instance);

var tasks = Enumerable.Range(0, 200).Select(_ => source.GetOrCreateAsync(Request())).ToArray();

await WaitUntil(() => engine.Calls >= 1);
await Task.Delay(50); // give the other 199 a bounded moment to arrive and queue behind the winner
gate.SetResult(true);

await Task.WhenAll(tasks);

engine.Calls.ShouldBe(1);
```

The winner is now held until the test releases it, so the overlap is a property of the test rather
than of the machine it runs on. (A reviewer pointed out afterwards that the determinism here is
stronger than it looks: all two hundred callers run synchronously through the cache check and the
in-flight registration before any of them suspends, so `engine.Calls` is already settled before the
wait. The gate is still the right structure, because that argument depends on the current
implementation and the gate does not.)

## Example 4: the mutation that proves it

Same class, and worth including because it is what a good answer to the question looks like.

The original design used a per-key semaphore. It coalesced correctly when synthesis succeeded, and
failed on exactly the path that matters: on a failure nothing is cached, so each of the 199 waiters
woke in turn, found the cache still empty, and called the engine itself. One outage became two
hundred requests against an endpoint that was already unhealthy.

The redesign shares one in-flight `Task` per key. The test that pins it is
`Two_hundred_simultaneous_readers_cause_one_synthesis_even_when_it_fails`, and against the old
implementation it fails with:

```
engine.Calls should be 1 but was 200
```

Not "an assertion failed". The number the defect predicts, on the nose. When your pull request
contains a line like that, a reviewer can stop wondering whether the test would have caught the bug.

## Example 5: the test name promises more than the test delivers

```csharp
[Fact]
public async Task A_cancelled_request_does_not_hang()
{
    using var cts = new CancellationTokenSource();
    await cts.CancelAsync();

    await Should.ThrowAsync<OperationCanceledException>(async () =>
        await Engine().SynthesizeAsync(new SynthesisRequest { Text = "Hello." }, cts.Token));
}
```

The token is already cancelled before the call, so this exercises the guard clause at the top of the
method and returns before any socket work happens. It is a correct test of a real thing. It says
nothing at all about whether an in-flight receive responds to cancellation, which is what the name
implies to anyone scanning the file.

This one was kept, not deleted. The problem was the name creating false confidence about a risk that
was genuinely uncovered, and the fix was a separate test for the real risk, driving a fake server
that accepts the connection and then says nothing:

```csharp
[Fact(Timeout = 5000)]
public async Task An_idle_connection_times_out_rather_than_hanging()
```

Names are read far more often than bodies. If a name describes a property, the body should test that
property, or the name should be narrower.

---

## Common shapes of a test that cannot fail

Collected from the examples above and from reviews on these repos. If a test you wrote matches one
of these, run the mutation before you open the pull request.

- **It asserts registration, not behaviour.** Resolving a service from DI, asserting a type is
  registered, asserting a route is present. All true with every method body emptied.
- **It asserts the shape of the result, not the content.** `ShouldBeOfType<JsonResult>()`,
  `ShouldNotBeNull()`, a 200 status and nothing about what came back.
- **The fixture makes both branches look the same.** Same seeded value for both cases, an absolute
  path where production takes a relative one, a default that happens to match the value under test.
- **It depends on timing to create the overlap it needs.** A delay, a sleep, a retry loop. Under a
  loaded runner it degenerates into the sequential case, which usually passes.
- **The assertion is true by construction.** The property held before the change and after it, so
  the test measures the language or the framework rather than your code.
- **It matches a substring.** One route assertion in this codebase passed under a rename because it
  matched a substring of the pattern. It was tightened to a per-segment check after the implementer
  mutation-tested its own assertion and found it.
- **It only exercises the guard clause.** The early return is tested; the work after it is not.

## When a property genuinely is not testable

Sometimes the honest answer to the question is "none", and the right move is to say so.

A real case from `read-aloud`. `DiskAudioCache.SetAsync` was writing files in place, which meant a
reader arriving mid-write could be served a truncated MP3 with no error at all: the file exists, so
the both-files-present check passes, and the read returns whatever bytes had been flushed. The fix
was write-to-temp-then-rename, because a rename on the same volume is atomic.

Two tests came with it. One asserts a successful write leaves no `*.tmp` files and exactly two
files; one asserts a cancelled write leaves no temp files and no entry. The implementer then
disclosed, rather than quietly shipping, that **both tests pass against the unfixed code**. The old
implementation never produced `.tmp` files and also always ended with exactly two, so the assertions
were true by construction under both. The cancellation test throws before touching the filesystem at
all.

That disclosure was the right call, and the reasoning was accepted: observing a torn read needs two
genuinely concurrent handles on one path, which needs a testability seam that was outside the scope
of that change. Atomicity of a same-volume rename is an operating system guarantee verified by
inspection, not something a sequential unit test can observe.

So the fix shipped, the two tests were kept as cleanup and cancellation-safety guards, and the
record says plainly that they are not proof of the property they sit next to.

What to do in that position:

1. **Make the fix anyway.** An untestable property is not a reason to leave a defect in place.
2. **Say what the test does prove and what it does not**, in the pull request description and
   ideally in a comment on the test. One sentence.
3. **Say what would be needed to test it properly**, if you know. A seam, a second process, a
   harness. That is a good issue for someone else to pick up.
4. **Do not stretch an assertion to look compliant.** A test that appears to cover the property and
   does not is worse than an acknowledged gap, because the next person reads the name and stops
   looking.

The reason this section exists: a contributor under pressure to satisfy a rule will write something
that passes review and proves nothing. I would much rather have the honest note. It has never cost
anyone a merge here.

## If you are working with an AI assistant

Please do, and mentioning it in the pull request is welcome rather than a mark against you. Some of
the best-reasoned changes in these repos were assisted, and one of the tightest findings on this
list came from an implementer mutation-testing its own route assertion and reporting the weakness it
found.

There is one specific failure mode worth knowing about, because it is consistent enough to check
for. Assistants are very good at producing code and tests that look complete, and the gap is almost
always the same one as Example 1: the test asserts that the thing is wired up rather than that it
behaves. Registration tests, not-null assertions, a route responding. Every one of those is
plausible, well named, and green with the feature removed.

The check is cheap and it is the same question:

> Name the production change that would make this test fail.

Then actually make that change, run the test, and confirm it goes red. Ask your assistant to do it
and paste the failure output. If the test stays green, you have found the gap before review did,
which is the entire point.

That single loop, run before you open the pull request, catches more than any amount of extra test
volume. It is also the difference between a review that is one round and a review that is three.

## Summary

- Every change needs a test that fails without it.
- Before opening a pull request, name the production change that would make each new test fail.
- Make that change, watch the test go red, put it back. Paste the output if it is interesting.
- If the answer is "none", say so in the description and explain why. That is welcome.
- Repo-level CONTRIBUTING files add to this and win where they disagree.
