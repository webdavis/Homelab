# PLAN-v12 experiments backlog

Companion to [PLAN-v12](PLAN-v12.md). Its
[publication scope and current decisions](PLAN-v12.md#publication-scope-and-current-decisions-2026-09-13)
govern this backlog. June research and proposed trials are retained for reference; this publication
supplies no deployment, trial-start or acceptance evidence. Every risky or uncertain service runs as an
**experiment** before it can become **core**. An experiment is time-boxed, has a hypothesis, explicit
**graduation criteria** (always including the ADR-0007 gates where data is involved), explicit **kill
criteria**, and a declared attention budget. Experiments live in their own namespace/quadlet scope and
may not block the core tracks. Graduating updates the service matrix row, the backup coverage table,
Gatus, and a runbook; killing an experiment records a one-paragraph postmortem here.

Status values: queued / running / graduated / killed / shelf (deferred with a named trigger).

______________________________________________________________________

## Track S, subscription replacement trials

### S1. KeePassium client trial (deferred)

- Status: **shelf** under the September instruction to retain KeePassXC/Strongbox. Trigger: an explicit
  decision to reopen the client trial. The June proposal below remains historical; no running trial or
  cancellation is asserted. Class: standard process, strict data. Proposed time-box: 30 days. Attention:
  minutes/week.
- Hypothesis: KeePassium gives equivalent daily iOS/macOS KeePass UX on the same kdbx, removing
  dependence on a post-acquisition app whose repo has been stale since 2025-11.
- Setup: install KeePassium on iPhone/Mac pointing at the existing kdbx (no data migration; Strongbox
  stays installed and pointed at the same file, which is the rollback).
- Graduation: 30 days of daily use; AutoFill verified across the usual apps; FaceID/OTP behavior
  acceptable on the free tier or the one-time Pro purchase accepted; no kdbx corruption or sync
  conflicts; decision note written.
- Kill: any kdbx write incompatibility, sync conflict pattern, or daily-UX regression that costs
  attention (ADR-0007 gate 5).

### S2. Actual Budget replaces YNAB [strict class]

- Status: queued (requires gate F2: DR proven; owner approved dual-entry + SimpleFIN 2026-06-11).
  Time-box: 60 to 90 days dual-entry. Attention: weekly during the trial (accepted, time-boxed).
- Hypothesis: Actual provides envelope-budgeting parity at YNAB fidelity with a superior export story
  (full zip = SQLite + metadata, re-import first-class) for $0 (or $1.50/mo with SimpleFIN bank sync).
- Setup: deploy on the NUC; import YNAB data via the official importer; nightly zip export to canonical
  storage + Restic; Authelia in front; both systems maintained in parallel.
- Graduation (all of ADR-0007 strict class): import verified against YNAB balances; monthly
  reconciliation matches across the whole run; **restore from B2 demonstrated**; **rollback (re-import to
  YNAB) demonstrated before cutover**; daily-UX verdict written; go/no-go note committed; only then
  cancel YNAB after one stable billing cycle, archiving the final YNAB export.
- Kill: reconciliation drift that costs more attention than YNAB's subscription; mobile-entry friction
  that breaks the habit loop (the ADHD tax counts).

### S3. Immich replaces Google Photos [standard, privacy-weighted]

- Status: shelf (owner confirmed 2026-06-11: not this cycle). Trigger: the 4TB NVMe lands in the NUC.
  Time-box: 60 days parallel. Attention: weekly during trial.
- Hypothesis: Immich v2.x (stable since 2025-10) delivers mobile auto-backup + search good enough to stop
  paying for Google storage, with originals as canonical files (ADR-0004).
- Setup: NUC k3s; its required Postgres+VectorChord stays an Immich-scoped instance (do not contaminate
  CNPG with extension requirements until proven); originals dir on the 4TB; built-in daily DB dumps +
  Restic.
- Graduation: 60 days of reliable iPhone background upload (Apple scheduling caveat verified in
  practice); ML smart-search useful on CPU; **restore demonstrated** (DB dump + originals into scratch);
  takeout archived; only then downgrade Google storage.
- Kill: background-upload unreliability (missed days), or the stack's care exceeding monthly attention.

### S4. Vikunja replaces Todoist

- Status: shelf. Trigger: Vikunja CalDAV/iOS maturity (currently self-described alpha) or Todoist
  pricing/trust change. Not scheduled in v12; Todoist stays per the matrix.

### S5. Forward Email as the webhook-native MX/routing layer (ADR-0012 Amendment 2)

- **Ownership (2026-06-11): executes in the clawmail project's repo**, not homelab; tracked here only as
  L1's external dependency. Homelab deploys clawmail + the cloudflared tunnel (the stable public
  endpoint) and commits the payload-contract pin the clawmail project publishes; since clawmail is
  sender-agnostic, this experiment swaps routing providers behind the tunnel URL without touching the
  homelab deployment.
- Status: queued (Stage 1 can start with L1; owner 2026-06-11: forward-everything scope, Stage 2 decided
  only on Stage-1 data). Class: standard process, staged to keep real mail out of the blast radius.
  Time-box: 30 days per stage. Attention: setup, then quarterly.
- Hypothesis: Forward Email's native alias-to-webhook delivery replaces the Cloudflare Email Routing +
  Worker layer with one provider feature, giving clawmail the AgentMail-style POSTs it was built for,
  plus simultaneous forward-to-mailbox.
- Setup, Stage 1 (zero-risk): `agent.webdavis.io` MX → Forward Email; webhook alias POSTs to the tunnel →
  clawmail; the Workspace forwarding rule feeds it; real mail untouched.
- Stage-1 graduation: 30 days of webhook-driven Elaine triage without message loss; the webhook payload
  contract verified against clawmail (parsed JSON vs raw MIME) and pinned in the repo; dual
  webhook+forward delivery on one alias demonstrated.
- Setup, Stage 2 (gated on Stage 1): apex `webdavis.io` MX → Forward Email; per-alias dual delivery
  (webhook + forward to the Gmail mailbox); SRS/deliverability watched for a billing cycle; rollback = MX
  records back to Google (documented before cutover).
- Kill: payload incompatibility, forwarding deliverability problems, or provider-reliability doubts →
  remain on the Amendment-1 wiring (Workspace forward → Cloudflare subdomain → Worker → tunnel), which
  stays fully specified as the fallback.
- Note: the human mailbox decision (Gmail vs Proton vs Fastmail) is deliberately independent; this
  experiment changes routing, not where mail rests.

### S6. Proton Mail as the human mailbox, via headless Bridge (ADR-0012 Amendment 3)

- Status: queued, **elevated** (2026-06-11: the Proton mailbox direction is locked and S6 is its gate;
  can run anytime, zero coupling to `webdavis.io`). Class: standard process, staged. Time-box: 30 days
  per stage. Attention: setup-heavy, then the Bridge's care cost IS the experiment's measurement.
- Hypothesis: Proton (app Stephen likes, existing paid account, E2EE at rest, bundled SimpleLogin
  aliases) can serve as the canonical mailbox despite having no public API, by running Proton Mail Bridge
  headless on the NUC for the agent action path.
- Facts (verified): Bridge has NO webhooks (local IMAP/SMTP server only); official CLI exists
  (`protonmail-bridge -c`); paid plan required (already held); auto-forwarding to external addresses is
  supported on paid plans, filter-scopable.
- Setup, Stage 1 (zero-risk): headless Bridge on the NUC logged into the **existing other-domain Proton
  account**; prove 30 days of unattended stability (keychain on headless Linux, survives reboots and
  Bridge updates, re-auth frequency measured); a small IMAP IDLE watcher converts new-mail events to
  local POSTs against a clawmail test route. **The action/reply tool is the himalaya CLI** (stateless,
  IMAP+SMTP against Bridge's local ports, driven by hermes as a terminal tool; config rendered by
  Ansible, Bridge-local credentials from OpenBao).
- Stage-1 graduation: 30 days with zero manual interventions beyond one documented re-auth; watcher
  latency under a minute; Elaine-style label/move actions proven **via himalaya** through Bridge IMAP and
  reversible; **a Stephen-prompted reply round-trip from Discord** (read forwarded mail → himalaya reply
  via Bridge SMTP → reply present in the Proton Sent folder; human-initiated, so permitted under ADR-0006
  without the autonomous-send gate).
- Stage 2 (only if Stage 1 graduates AND Stephen wants to leave Workspace): `webdavis.io` mailbox
  migration per ADR-0007 standard class (IMAP import, 30-day parallel via auto-forward both ways,
  Workspace Drive/Docs/Meet coupling resolved, rollback documented). Wiring options per ADR-0012
  Amendment 3: auto-forward → Forward Email webhooks (Wiring A) or Bridge-IDLE local ingestion (Wiring B,
  which deletes the public tunnel).
- Kill: Bridge needs manual babysitting more than monthly, or re-auth loops; postmortem notes Proton
  stays the other-domain personal mailbox and `webdavis.io` stays on the Amendment-1/2 wiring.

______________________________________________________________________

## Track A, AI/devops platform experiments

### A-E1. Langfuse (LLM tracing)

- Status: queued (after A2 CI exists). Time-box: 45 days. Attention: setup-heavy, then passive.
- Hypothesis: with the hermes langfuse plugin emitting traces for free, having traces changes how agent
  misbehavior is debugged at least weekly; that justifies a 5-service stack (Postgres + ClickHouse +
  Redis + S3/MinIO + app).
- Setup: experiment namespace on the NUC sized per official compose guidance; hermes plugin pointed at
  it; **fail-open** (tracing outage must never break agents).
- Graduation: ≥4 real debugging sessions in the box that used traces decisively; its own backup story
  implemented (PG + ClickHouse + S3 trio) and one restore demonstrated; RAM within ~6GB measured.
- Kill: traces looked at less than weekly; or the stack pages/needs care more than monthly. Postmortem
  fallback: provider dashboards + Loki logs.

### A-E2. LiteLLM proxy (spend/budget gateway)

- Status: queued (lowest priority; candidate-reject). Time-box: 30 days.
- Hypothesis: central per-key spend tracking across hermes + Hindsight + scripts produces at least one
  provider/budget decision per month that dashboards alone would miss.
- Setup: experiment namespace; route only Hindsight's internal LLM through it first (lowest-risk
  consumer); hermes keeps native `fallback_providers` (do not double-route).
- Graduation: a real decision changed by its data; Postgres dependency + upgrade treadmill accepted in
  writing; secrets-holding surface reviewed.
- Kill (expected): data is interesting-but-inert after 30 days. Reject and note it.

### A-E3. Ollama (CPU utility models)

- Status: queued. Time-box: 30 days.
- Hypothesis: small local models (3-8B q4, async only) add value for Paperless tag suggestion and
  Karakeep auto-tagging without cloud calls on private documents.
- Setup: systemd or k3s on the NUC; batch jobs only; never wired into interactive agent paths (ADR-0003).
- Graduation: one production batch job (e.g. nightly Paperless tag suggestions with human-confirm queue)
  whose suggestions get accepted >50% of the time; RAM transient only.
- Kill: tok/s makes jobs miss their nightly window, or suggestion quality wastes more review time than it
  saves.

### A-E4. Knowledge corpus quality (core-track rollout with experiment-style gate)

- Status: queued (Track A4 is core; this is its acceptance experiment).
- Graduation: Bob answers ten held-out questions about the repos ("why was Wazuh deferred", "what is the
  clawmail payload contract", "which Pi runs ntfy") with correct canonical-path citations ≥8/10; the
  canary-doc re-ingest test passes in CI weekly.
- Kill: n/a (core); failures feed ingestion fixes.

______________________________________________________________________

## Track L, life automation rollouts (autonomous workflows; ADR-0006 gates)

Each autonomous workflow ships only with: central logging, a surfaced run-digest, a documented undo, an
allowlisted action set, a rate limit, and a one-command kill switch. These are rollouts with gates rather
than science experiments, listed here because each must *prove* its gate before widening.

### L-R1. Morning brief (first autonomous workflow)

- Status: queued (after L1). Gate to enable: read-only sources (calendar, Todoist, Elaine's overnight
  summary, alerts, FreshRSS/Karakeep picks) assembled to one Markdown brief, archived to the vault,
  delivered by 07:30.
- Widen-gate: 14 consecutive deliveries without a factual mis-assembly complaint.
- Kill switch: disable the cron job.

### L-R2. Elaine autonomous filing (classify/tag/file/summarize)

- Status: queued (after the clawmail payload contract is pinned, gate L1).
- Gate: 30 days of classification with ≤2 misfiles/week (misfile = Stephen reverses her action); all
  actions reversible (unarchive/untag) and logged.
- Widen-gate (send-as-Stephen for allowlisted templates only): 90 days clean per ADR-0006; per-message
  confirm until then.

### L-R3. Resurfacing jobs (deadline/commitment recall)

- Status: queued (after A4 corpus + L-R1). Gate: weekly digest of resurfaced items where ≥1/3 are rated
  useful for a month. Kill: noise rated higher than value for two consecutive weeks (tune or stop).

### L-R4. Paperless auto-ingest from Elaine

- Status: queued (after L3 + L-R2). Gate: "file this receipt" round-trip works with correct doc-type
  tagging ≥80%; originals always land regardless of tagging quality (fail-safe to inbox tag).

### L-R5. vpp (Voice Processing Pipeline)

Status: queued, planning only. The operator named vpp on 2026-09-12 and chose Rust. It carries forward
the local voice-capture experiment and the broader transcription work in PLAN-v11, Phase 6.
[Planning task](https://app.todoist.com/app/task/6hVpPJC2cjJW3V9M).

- [ ] Discover fully synced Apple Voice Memos on the Mac through a verified supported access/export path.
  Preserve original audio and capture metadata; handle interrupted sync, retries and repeated discovery
  without losing recordings or creating duplicate notes. Keep audio, transcripts and analysis separately
  linked. Reconcile Ivy's existing `agent-processing-pipeline/` layout before implementation.
- [ ] Use redundant transcription to find disagreements, particularly names, numbers and dates. Keep
  alternatives and source references, check generated notes against the transcript, and flag unresolved
  issues for review. Agreement between engines is not proof of correctness. Playing audio by selecting a
  summary sentence is rejected; preserving original recordings is still required.
- [ ] Notify the operator about potential transcription or note errors through pns's producer application
  programming interface (API). Integrate at runtime through `pns submit --json`, with `producer: "vpp"`
  and `signal.kind: "needs_attention"`. Keep review state in vpp; a notification receipt does not mean
  the user reviewed or corrected the note. Reverify the protocol when implementing.
- [ ] Let agent analysis suggest tags and relationships across recordings. Define structured metadata,
  stable recording identifiers and explicit note links; use deterministic configurable filing rules. Tags
  alone do not move files. Write portable Markdown to a user-selected directory, optionally inside an
  Obsidian vault, where existing sync can deliver it to mobile. Obsidian is not a dependency.
- [ ] Prepare meeting briefs from relevant notes, including source references and unresolved issues.
  Optional read-only calendar context can identify meetings, times and participants; optional Todoist
  context can supply relevant tasks, deadlines and completion status. Limit sources to user-selected
  calendars/projects and verify the available permission boundaries. Requested versus automatic briefs,
  scheduling ownership, providers and lead times remain design questions.
- [ ] Let Bob, the planned Hermes executive assistant, consume vpp's notes, metadata and briefs. Decide
  whether Bob supplies meeting/task context or vpp reads it directly when that integration is designed.
  Bob must retain uncertainty and provenance when using the outputs. vpp remains useful independently;
  this integration does not bring Forzare forward from its post-modernization schedule.
- [ ] Define an optional supported handoff to Open Notebook under L6, preserving one automatic
  capture/transcription pipeline and canonical originals. vpp and Bob must read and produce ordinary
  notes without Open Notebook; settle the handoff format during integration design.
- [ ] Produce a separate redacted draft for sharing, with human review before release. Preserve the
  private original; generating a draft does not authorize sending it.
- [ ] Choose transcription engines, local/cloud processing, summary format and retention before
  implementation. Speaker labels and dated digests remain candidates. vpp owns application code; dotfiles
  owns Mac installation/configuration, homelab owns deployments, and the configured output directory owns
  the user's content. The earlier trial's usage hypothesis (three uses per week, review usefulness after
  a month) remains an evaluation aid, not permission to delete recordings or notes.

### H-R1. Home Assistant cautious automations

- Status: queued (after H1). Cap: 2-3 automations; lights/reminders/presence only; no locks/security.
  Gate per automation: 14 days of logs with zero surprising actuations before the next one is added.

______________________________________________________________________

## Learning-track / shelf (named triggers, not time-boxes)

| Experiment                                                            | Status                                                                    | Trigger to start                                                | Spec                                                                |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------- |
| Cilium (CNI, NetworkPolicy, Hubble)                                   | **selected for core** (2026-06-11, ADR-0008 reversed; acceptance pending) | n/a, day-one Track 0                                            | corrected PLAN-v11 1.1b + policy-surface findings                   |
| Longhorn (replicated storage)                                         | **selected for core** (2026-06-11, ADR-0008 reversed; acceptance pending) | n/a, day-one Track 0                                            | corrected PLAN-v11 1.1c + drills                                    |
| Second Pi 5 cold standby (pre-imaged monitoring swap)                 | shelf                                                                     | homelab stable (core tracks done)                               | question 2/8 decision 2026-06-11; promote-the-standby restore drill |
| Wazuh (fleet SIEM)                                                    | shelf                                                                     | 3+ Linux hosts, or a real CVE/SCA reporting requirement         | corrected PLAN-v11 3.12; official 8GiB floor acknowledged           |
| Hermes sandboxed investigator (Mouse reference, Critical alerts only) | shelf                                                                     | existing investigation design and dotfiles task 24 gates        | advisory after the original alert; never gates or delays delivery   |
| Headscale (self-hosted coordination)                                  | shelf                                                                     | Tailscale pricing/policy change, or privacy requirement hardens | ADR-0002 alternatives note                                          |
| Radicale (CalDAV/CardDAV)                                             | shelf                                                                     | calendar self-hosting prioritized                               | research notes (flat-file storage; beats Baikal on cadence)         |
| Wazuh-class osquery fleet manager (Fleet/Kolide)                      | shelf                                                                     | same trigger as Wazuh; compare then                             | dotfiles research inputs                                            |

______________________________________________________________________

## Graduation checklist (applies to every experiment → core promotion)

1. ADR-0007 gates passed where user data is involved (backup, restore, export round-trip, security, daily
   UX, rollback, lock-in).
1. Service matrix row updated with measured RAM and attention class.
1. Backup coverage row added with a **passed** restore (or an explicit rebuildable-declaration + rebuild
   drill).
1. Gatus check live; alerts routed.
1. Runbook committed: deploy, upgrade, restore, kill switch.
1. For autonomous workflows: ADR-0006 evidence (logs, undo, allowlist, rate limit, kill switch)
   demonstrated, not asserted.
