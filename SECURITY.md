# Security Policy

## Reporting a vulnerability

**Do not open a public issue.**

Email **arnelirobles@gmail.com** with `SECURITY` in the subject, or use GitHub's private
[security advisory](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
form on the affected repository.

Include whatever you have. A rough description of the problem is more useful than nothing,
and a reproduction is more useful than a careful description:

- Which package and version
- What an attacker can do that they should not be able to
- Steps to reproduce, or a minimal program that demonstrates it
- Anything you already know about the cause

## What happens next

| When | What |
|---|---|
| Within 3 days | Acknowledgement that the report arrived and is being read |
| Within 14 days | An assessment: whether it is a vulnerability, how severe, and a rough fix timeline |
| On release | A patched version, an advisory, and credit to you unless you prefer otherwise |

These are the targets of one person maintaining these projects alongside other work, not a
contractual SLA. If something is being actively exploited, say so in the subject line and it
will be treated accordingly.

## Supported versions

The **latest published release** of each package receives security fixes. Older majors are
not patched unless the issue is severe and the upgrade path is genuinely disruptive.

## Scope

In scope: anything in a published package that lets an attacker read data they should not,
execute code, escalate access, or corrupt another user's state.

Worth reporting even if you are unsure it qualifies: data leaking across tenants or sessions,
anything that deserialises untrusted input, anything touching persistence, credentials, or
outbound requests.

Out of scope: vulnerabilities in dependencies that are already public and have an upstream
fix (report those upstream), findings from automated scanners with no demonstrated impact,
and issues that require an attacker to already control the machine.

## Disclosure

Please give a reasonable window to ship a fix before publishing. In return you will get
credit in the advisory and the release notes, and will not be asked to stay quiet
indefinitely.
