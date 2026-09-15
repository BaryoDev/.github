# ☕ BaryoDev

**Software from the baryo, shipped to the world.**

*Baryo* is Filipino for village. This is the open-source home of an independent
software consultant from the Philippines: 14 years of building systems end to
end, publishing the parts that don't ship under NDA.

---

## The barako café

The flagship. Four products that ship a client's system from the same images,
configured rather than rewritten.

> **Model it in barakoCMS. Edit it in barakoBrew. Render it with barakoPress. Deploy it anywhere.**

| Product | What it is |
| --- | --- |
| [**barakoCMS**](https://github.com/BaryoDev/barakoCMS) | The API. .NET 10 on Marten and PostgreSQL: runtime content types, workflows, roles and field sensitivity, multi-tenancy with custom domains, and opt-in modules as NuGet packages |
| [**barakoBrew**](https://github.com/BaryoDev/barakoBrew) | The console. Where content types, pages, roles, workflows and each site's look are set up, against the API |
| [**barakoPress**](https://github.com/BaryoDev/barakoPress) | The renderer. One Next.js app serving many sites from the same image, each with its own domain, identity and theme |
| [**BaryoVM**](https://github.com/BaryoDev/BaryoVM) | The deploy tool. Agentless deploys over SSH to VMs you own, from one Go CLI |
| [**barako-client**](https://github.com/BaryoDev/barako-client) | A typed, tenant-aware TypeScript client for the API |

[barakocms.com](https://barakocms.com) · [docs](https://barakocms.com/docs/) · [roadmap](https://barakocms.com/roadmap/) · [live console](https://playground.baryo.dev/barakocms)

---

## Start here

| If you are... | Go to |
| --- | --- |
| Building a **client site or business system on .NET** | [The barako café](#the-barako-café) |
| A **.NET developer** who wants one small, fast library | [Verdict](https://github.com/BaryoDev/Verdict) · [Carom](https://github.com/BaryoDev/Carom) · [Mapsicle](https://github.com/BaryoDev/Mapsicle) · [Talaan](https://github.com/BaryoDev/Talaan) |
| A **JS/TS developer** | [rnxjs](https://github.com/BaryoDev/rnxjs) · [rnxORM](https://github.com/BaryoDev/rnxORM) · [DopamineJS](https://github.com/BaryoDev/dopaminejs) · [pwa-kit](https://github.com/BaryoDev/pwa-kit) |
| Running an **Umbraco site** | [Umbraco PWA](https://github.com/BaryoDev/umbraco-pwa) · [Umbraco Read Aloud](https://github.com/BaryoDev/umbraco-read-aloud) |
| **Evaluating the engineering** | [Verdict](https://github.com/BaryoDev/Verdict) for the design thesis, [barakoCMS](https://github.com/BaryoDev/barakoCMS) for the largest system |

---

## The design thesis

Every .NET library here is built the same way, deliberately:

> **A small core that costs nothing, with capability added as opt-in packages.**
> Installing one never drags in a dependency you did not ask for.

`Verdict` core is zero-allocation and grows into eight packages. `Carom` core is
13 KB with zero dependencies and grows into six. `Mapsicle` core has zero
dependencies and grows into twelve. `barakoCMS` ships a lean core and adds
accounting, forms, pages, analytics, email and storage as modules you compose
per project.

---

## .NET packages

| Package | What it does | Latest |
| --- | --- | --- |
| [**Verdict**](https://github.com/BaryoDev/Verdict) | Zero-allocation `Result<T>` for error handling without exceptions. Benchmarked far faster than the common alternatives. Eight opt-in packages: `.Extensions`, `.Async`, `.Fluent`, `.Json`, `.Rich`, `.Logging`, `.AspNetCore` | [![NuGet](https://img.shields.io/nuget/v/Verdict?label=)](https://www.nuget.org/packages/Verdict) |
| [**Carom**](https://github.com/BaryoDev/Carom) | Resilience: retry, timeout, circuit breaker, fallback, bulkhead, rate limiting. 13 KB zero-dependency core, decorrelated jitter mandatory by default | [![NuGet](https://img.shields.io/nuget/v/Carom?label=)](https://www.nuget.org/packages/Carom) |
| [**Mapsicle**](https://github.com/BaryoDev/Mapsicle) | Object mapping. Twelve packages with an explicit dependency graph; EF Core, Dapper, validation, caching and audit are all opt-in | [![NuGet](https://img.shields.io/nuget/v/Mapsicle?label=)](https://www.nuget.org/packages/Mapsicle) |
| [**Talaan**](https://github.com/BaryoDev/Talaan) | Spreadsheet and CSV reader for .NET. `.xlsx` and CSV with no external dependencies | [![NuGet](https://img.shields.io/nuget/v/Talaan?label=)](https://www.nuget.org/packages/Talaan) |

## JavaScript and TypeScript packages

| Package | What it does | Latest |
| --- | --- | --- |
| [**DopamineJS**](https://github.com/BaryoDev/dopaminejs) | Game-feel engine for the web: XP, achievements, streaks, particles, synthesized sound. Ships TypeScript declarations | [![npm](https://img.shields.io/npm/v/dopaminejs?label=)](https://www.npmjs.com/package/dopaminejs) |
| [**rnxjs**](https://github.com/BaryoDev/rnxjs) | Reactive UI framework in TypeScript. 646 passing tests across Vitest and Playwright | [![npm](https://img.shields.io/npm/v/@arnelirobles/rnxjs?label=)](https://www.npmjs.com/package/@arnelirobles/rnxjs) |
| [**rnxORM**](https://github.com/BaryoDev/rnxORM) | TypeScript ORM for Node.js. PostgreSQL, SQL Server and MariaDB, with integration tests | [![npm](https://img.shields.io/npm/v/rnxorm?label=)](https://www.npmjs.com/package/rnxorm) |
| [**pwa-kit**](https://github.com/BaryoDev/pwa-kit) | Drop-in PWA kit: install prompt for Android and iOS, network-first service worker | [![npm](https://img.shields.io/npm/v/@baryodev/pwa-kit?label=)](https://www.npmjs.com/package/@baryodev/pwa-kit) |
| [**read-aloud**](https://github.com/BaryoDev/read-aloud) | Read-aloud for any site using Edge neural TTS. Headless controller plus a web component | [![npm](https://img.shields.io/npm/v/@baryodev/read-aloud?label=)](https://www.npmjs.com/package/@baryodev/read-aloud) |
| [**feed-slurp**](https://github.com/BaryoDev/feed-slurp) | Universal RSS and Atom fetcher that runs in the browser | [![npm](https://img.shields.io/npm/v/feed-slurp?label=)](https://www.npmjs.com/package/feed-slurp) |
| [**BaryoDev.Libraries.JavaScript**](https://github.com/BaryoDev/BaryoDev.Libraries.JavaScript) | Zero-dependency TypeScript utilities, released with Changesets | npm |

## For Umbraco sites

| Package | What it does | Latest |
| --- | --- | --- |
| [**Umbraco PWA**](https://github.com/BaryoDev/umbraco-pwa) | Turns an Umbraco site into an installable, offline-capable app, and shows who installed it from your own backoffice | [![NuGet](https://img.shields.io/nuget/v/BaryoDev.Umbraco.Pwa?label=)](https://www.nuget.org/packages/BaryoDev.Umbraco.Pwa) |
| [**Umbraco Read Aloud**](https://github.com/BaryoDev/umbraco-read-aloud) | Read-aloud for an Umbraco site using Edge neural voices, with audio cached on your own server | [![NuGet](https://img.shields.io/nuget/v/BaryoDev.Umbraco.ReadAloud?label=)](https://www.nuget.org/packages/BaryoDev.Umbraco.ReadAloud) |

## How I build

| Project | What it is |
| --- | --- |
| [**lean-agent-method**](https://github.com/arnelirobles/lean-agent-method) | How I run AI coding agents over a backlog without burning a plan in a night, with an adversarial review skill |
| [**template-project**](https://github.com/BaryoDev/template-project) | Universal project template wired to the BaryoDev skills library for AI-assisted development |
| [**create-baryo-app**](https://github.com/BaryoDev/create-baryo-app) | Scaffold a new project the Baryo way |
| [**Baryo.CLI**](https://github.com/BaryoDev/Baryo.CLI) | Local AI chat CLI over Docker Model Runner. Models run entirely on your machine: no API keys, no cloud |

## Design assets

| Project | What it is |
| --- | --- |
| [**Kapehan**](https://github.com/BaryoDev/Kapehan) | Free, hand-drawn coffee SVG icons ☕ |

## Examples and experiments

Smaller repos, kept public because working code explains more than prose. Not
maintained to package standards.

[Verso](https://github.com/BaryoDev/Verso) (an Electron editor) ·
[dopa-dopa](https://github.com/BaryoDev/dopa-dopa) (a game built with DopamineJS) ·
[rnxJS_samples](https://github.com/BaryoDev/rnxJS_samples) ·
[HTMLGames](https://github.com/BaryoDev/HTMLGames) ·
[SimpleMobileGames](https://github.com/BaryoDev/SimpleMobileGames) ·
[NovelAssistant](https://github.com/BaryoDev/NovelAssistant)

---

## How the pieces fit

Most of these were built because something else here needed them.

- **barakocms.com** runs on barakoCMS and barakoPress, and is deployed with BaryoVM.
- **barako-client** is how a TypeScript app talks to barakoCMS.
- **DopamineJS** powers dopa-dopa, and **rnxjs** is shown in rnxJS_samples.

## How things are built here

The same conventions across every repo, which is the point:

- **Tests in CI on every push.** Verdict has 551, rnxjs 646, DopamineJS 95
- **Published, not just pushed.** If it has a README claiming it works, it is on NuGet or npm
- **Zero or few dependencies.** Especially in cores
- **Benchmarks over adjectives.** Performance claims come with numbers you can re-run
- **AI-assisted development, deliberately.** Hand-authored `CLAUDE.md` and `AGENTS.md` context files per repo, and a separate critic that tries to disprove every finding before it is reported

---

## Thank you

These projects are unfunded and everything here is voluntary, so every one of
these is someone choosing to spend their evening on somebody else's codebase.
Named for what they actually did, because "3 contributions" tells you nothing
about the work.

| | |
| --- | --- |
| [**@snowyukitty**](https://github.com/snowyukitty) | Found that Verdict returned pooled buffers to the pool only on the success path, so an enumeration that threw leaked them. Shipped in `Verdict 2.8.0` |
| [**@zacharywomack8-source**](https://github.com/zacharywomack8-source) | Noticed three Carom packages were being published to NuGet while missing from the solution file, so CI had never built them. Also killed a test that slept for about fifteen minutes on every run |
| [**@BabuBahir**](https://github.com/BabuBahir) | Conditional Swagger for BarakoCMS. Then worked out that `GET /api/content-types` reads a document type nothing ever writes, and, more usefully, that fixing it the obvious way would have published the whole schema to anonymous callers |
| [**@ahmdkaml**](https://github.com/ahmdkaml) | The BarakoCMS sitemap endpoint, and public search text. Turned around a long review in an afternoon and asked the right question before writing code |
| [**@alitorabi-dev**](https://github.com/alitorabi-dev) | Made the Umbraco PWA package report readiness failures at startup instead of staying quiet until someone noticed the install prompt never appeared |
| [**@bharathh866**](https://github.com/bharathh866) | Read the Umbraco Marketplace listing properly and said what was wrong with it, including cards that were cutting off. Feedback nobody is obliged to give |
| [**@jlongyam**](https://github.com/jlongyam) | Fixed a typo in an rnxjs sample binding. Small, and it was wrong for a long time before somebody bothered |
| [**@KingEmma7**](https://github.com/KingEmma7) | Corrected the BarakoCMS Files module documentation, which had drifted from what the module actually does |
| [**@MrBeldum**](https://github.com/MrBeldum) | `vm exec` for BaryoVM: run a one-off command on a registered VM without opening a shell yourself |

From Japan, Egypt, Iran and a few places not stated. Thank you, genuinely.

**Want to join them?** Every repo has issues tagged
[`good first issue`](https://github.com/search?q=org%3ABaryoDev+is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22&type=issues)
and [`help wanted`](https://github.com/search?q=org%3ABaryoDev+is%3Aissue+is%3Aopen+label%3A%22help+wanted%22&type=issues).
Comment `/take` on one and it is assigned to you within the minute, no waiting on
a maintainer. The one rule is that a change needs a test that fails without it,
and there is a worked guide for that in
[TESTING.md](https://github.com/BaryoDev/.github/blob/main/TESTING.md).

---

🌐 [baryo.dev](https://baryo.dev) · ☕ [barakocms.com](https://barakocms.com) · 📦 [NuGet](https://www.nuget.org/profiles/arnelirobles) · [npm](https://www.npmjs.com/org/baryodev) · [Container images](https://github.com/orgs/BaryoDev/packages) · ✍️ [Blog](https://baryodev.medium.com/) · 📫 [Say hello](https://baryo.dev/about)
