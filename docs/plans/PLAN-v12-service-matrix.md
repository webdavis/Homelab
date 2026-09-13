# PLAN-v12 service matrix

Companion to [PLAN-v12](PLAN-v12.md). Its
[publication scope and current decisions](PLAN-v12.md#publication-scope-and-current-decisions-2026-09-13)
govern this matrix, including unpublished source dependencies and the retained June research. Decisions
describe the portfolio; they do not assert deployment or acceptance. Field key:

- **Decision:** keep / add / replace / experiment / defer / reject.
- **Attention:** the recurring operator-care class (none / quarterly / monthly / weekly). Weekly must
  justify itself against the north star.
- **Targets:** NUC (k3s unless noted), Pi (systemd/Podman quadlets), Mac (`dresden`), SaaS.
- **Gates:** test gates are the layer-2/3/4 checks a service must hold; migration gates apply only to
  replacements (ADR-0007).

Kerberos/LLDAP/SSSD/fail2ban were restored by the June owner decision (ADR-0010). September additions are
Infisical, NetBird, Dozzle and Open Notebook. Read each entry for its current gates.

______________________________________________________________________

## 1. Agent and memory layer (the product)

### hermes-agent (gateways: bob, elaine, sierra)

- Category: agent runtime. **Decision: keep** (core). Default: hermes-agent (Nous Research), one profile
  per persona. Ranked alternatives: none serious at this investment level (OpenClaw decommissioned;
  rebuilding on raw SDKs rejected as toil).
- Purpose: the AI assistant layer; Bob (general/engineering copilot, Discord), Elaine (paranet manager:
  clawmail email + iMessage), Sierra (isolated second user).
- Primary outcome: ADHD externalized executive function; triage without being asked.
- AI/life value: the delivery vehicle for every Track L workflow. AI/devops value: Bob is the
  human-supervised engineering agent (ADR-0006). Subscription value: replaces nothing directly; enables
  replacements.
- Target: NUC, **native systemd** (not k3s). State: `~stephen/.hermes` per profile (config, `auth.json`,
  `state.db`, `jobs.json`, workspaces). Auth/secrets: per-route HMAC (one key per webhook route, never
  shared), OpenBao-rendered `.env`, Codex OAuth in `auth.json`; Sierra per v11 §5.13 sandbox.
- Backup/restore/export: Restic nightly of `~/.hermes` (NUC + Pi repo); quarterly restore drill must
  prove OAuth-token survival. Config canonical in the homelab repo (boundary proposal: homelab owns the
  route registry).
- Test gates: `hermes gateway status` smoke; `webhook test` per route; `cron tick`; synthetic Discord
  round-trip.
- Burden: weekly (it is the product; accepted). Risk: high-privilege by design; mitigated by ADR-0006
  tiers + per-route secrets + Sierra sandbox. Hardware fit: trivial CPU/RAM (~2GB with clawmail).
- Dependencies: Hindsight, OpenBao, clawmail, Discord/BlueBubbles. Track: L1.
- Rationale: proven in v9-v11 design + as-built Mac pipeline; the rest of the portfolio feeds it.

### Hindsight (memory service)

- Category: agent memory/RAG. **Decision: keep** (core). Default: self-hosted full image (bundled local
  embedder + reranker). Alternatives: Honcho (conflicts, single provider slot), bare pgvector DIY
  (rebuilding retain/recall/reflect, rejected).
- Purpose: retain/recall/reflect memory; per-agent private banks + shared knowledge banks
  (`homelab-knowledge`, `obsidian-vault`, `karakeep`).
- Primary outcome: "the system remembers so Stephen does not have to"; grounded agent answers with
  canonical-path citations (ADR-0004).
- AI/life value: resurfacing jobs (Track L4), morning-brief memory. AI/devops value: the repo-grounding
  corpus (Track A4). Subscription value: none direct.
- Target: NUC k3s, service on :8888 reachable by the native gateways (host-reachable address per v11 L15
  fix). State: Postgres (CNPG) + local model weights (baked in image).
- Auth: `TENANT_API_KEY` + per-bank MCP tokens from OpenBao. Backup/restore/export: banks ride Barman
  PITR; banks are *derived-with-nuance* (ADR-0004): durable facts must also exist in canonical files;
  rebuild = re-ingest jobs; knowledge canary test (layer 4).
- Test gates: retain/recall round-trip; canary doc re-ingest; `:8888/metrics` scraped.
- Burden: monthly. Risk: moderate (private data in banks; LAN-only, token-gated). Hardware fit: ~3GB.
  Dependencies: CNPG, OpenRouter/Nous (internal LLM, off-box per ADR-0003).
- Track: L1/A4. Rationale: the memory layer everything cites; embedder/reranker model choice locked
  before first write (dimension immutability).

### clawmail (+ cloudflared tunnel)

- Category: email ingress (the **agent plane**; ADR-0012). **Decision: keep** (core; ADR-0002
  re-classifies it private-to-Stephen). Alternatives: plain IMAP polling by Elaine (the documented
  de-risking fallback; deletes the ingress but also the filtering pipeline).
- **Ownership boundary (2026-06-11): homelab deploys and operates the service AND the cloudflared
  tunnel.** The tunnel is homelab ingress infrastructure: a stable public HTTPS endpoint terminating at
  clawmail's service (k3s manifests for both, secrets via ESO, archive PVC backup, Gatus/Blackbox
  liveness). **clawmail is sender-agnostic**: it accepts any POST conforming to its payload contract at
  that endpoint and does not care who forwards the mail. **The routing mechanics belong to the clawmail
  project**: MX records, the routing provider (Forward Email / Cloudflare / a mailbox auto-forward),
  forwarding rules, the payload contract, and the S5 staging live in the clawmail repo; swapping routing
  providers is config pointed at the homelab-provided tunnel URL, touching neither deployment.
- Purpose: receives webhook POSTs from the clawmail project's routing layer via the tunnel,
  security-filters + workflows them, and delivers to Elaine's hermes route. The human mailbox holds
  primary delivery; **the agent pipeline is never the only path to mail** (ADR-0012). Upstream wiring
  details: clawmail repo.
- Primary outcome: zero-touch email triage, the single highest-ADHD-value flow, with direct-app access
  preserved when the agent plane is down.
- Target: NUC k3s (clawmail container + cloudflared). State: processing archive + config (the human
  mailbox is the system of record per ADR-0012). Auth: Cloudflare Access service token + WAF +
  HMAC-signed posts; quarterly Access-policy review.
- Backup/restore/export: archive + config via Restic; restore spot-check monthly. Export: mail is files.
- Test gates: end-to-end synthetic email (layer 4) asserting the **pinned payload contract** (Track L1
  gate); tunnel Blackbox probe; tokenless request 403s; **agent-plane-down drill: mail still arrives in
  the human mailbox app**.
- Burden: monthly. Risk: the one public surface; three gates in front; monitored. Hardware fit: \<0.5GB.
  Dependencies: hermes, Cloudflare free tier (rate-limit window 10s-capped). Track: L1.
- Rationale: Stephen's own ingress app with filtering already designed; IMAP fallback documented keeps it
  honest.

### Human mailbox provider (the **human plane**; ADR-0012 + Amendments)

- Category: email (SaaS). **Decision (locked 2026-06-11): Workspace stays canonical today; the Proton
  migration is the chosen direction, gated on S6 graduating** (Amendments 2-3). Forwarding scope:
  forward-everything (Elaine's triage is the filter). The mailbox is decided independently of the webhook
  question: the routing layer below provides webhooks, so the mailbox only has to win on app quality.
  Ranked replacements if leaving Google entirely (ADR-0007 standard class): **1. Proton Mail** (Amendment
  3: app Stephen likes, existing paid account, E2EE at rest, SimpleLogin aliases; cost: no public API, so
  Elaine's action path requires headless Bridge as a 24/7 NUC service, evaluated by experiment S6 against
  the other-domain account first), **2. Fastmail** (best remaining non-Google app + custom domain;
  verified NOT webhook-native, which no longer matters). Rejected: self-hosted MX (CGNAT + deliverability
  \+ attention), AgentMail-as-mailbox (no app, by its own positioning).
- Purpose/outcome: mail always readable/sendable in a first-class app, independent of every homelab
  component. Cost: Workspace Business-Starter class ~$7/user/mo (verify); **dropping Workspace also drops
  domain Drive/Docs/Meet, a named gate item for any future mailbox migration**.
- Target: external SaaS. State: the canonical mail store (ADR-0004). Auth: provider app + Gmail API OAuth
  for Elaine's reversible label/archive actions (ADR-0006).
- **Gmail push/Pub-Sub: re-graded to viable-non-default Wiring C** (ADR-0012 Amendment 4: daily scripted
  `watch()` renewal is Google's documented usage and fits the cron+dead-man pattern; costs that keep it
  non-default: GCP apparatus, ping-not-message payload forcing a clawmail rework, and the tunnel
  survives). Default remains the routing-layer webhook (S5).
- Backup/export: periodic Takeout/IMAP pull archived to canonical storage; Elaine's copies are
  derivative.
- Test gates: layer-4 synthetic asserting delivery to the mailbox **with the agent plane disabled**.
- Burden: none. Track: L1. Rationale: app quality is the mailbox's only job now.

### Forward Email (webhook-native MX/routing layer; ADR-0012 Amendment 2)

- **Ownership (2026-06-11): the clawmail project's concern**, recorded here only because ADR-0012 decided
  the architecture; setup, staging, and the payload-contract pin execute in the clawmail repo. Homelab's
  only dependency: a deployed clawmail receiving POSTs.
- Category: email routing (SaaS; OSS codebase). **Decision: experiment, staged** (Track S, standard
  class). Purpose: the **AgentMail-style native webhook layer for the domain**: verified, an alias can
  deliver to a webhook URL ("use webhooks as a global or individual alias to forward emails to"),
  replacing the Cloudflare Email Routing + Worker contraption with one provider feature, while
  simultaneously forwarding to the human mailbox.
- **Stage 1 (zero-risk):** `agent.webdavis.io` subdomain MX → Forward Email; its webhook POSTs feed the
  existing tunnel → clawmail. Real mail untouched. **Stage 2 (apex cutover, gated):** `webdavis.io` MX →
  Forward Email; per-alias webhook + mailbox-forward dual delivery; rollback = MX back to Google
  (DNS-fast, documented).
- Verify-at-trial: webhook payload shape vs clawmail's contract (full parsed JSON vs raw MIME);
  simultaneous webhook+forward on one alias; SRS/deliverability on forwards to Gmail; pricing for any
  paid tier used.
- Graduation: Stage-1 webhooks driving Elaine for 30 days without loss; payload contract pinned; then the
  Stage-2 go/no-go note. Kill: payload/deliverability problems → stay on the Amendment-1 wiring
  (Workspace forward → Cloudflare subdomain → Worker).
- Burden: quarterly after setup. Risk: a smaller third party enters the mail path (staged exactly so the
  blast radius is the agent copy first). Track: S/L1.

### AgentMail (agent-owned inboxes)

- Category: agent email (SaaS, API-first). **Decision: experiment, scoped** (ADR-0012): only for inboxes
  agents own outright (Bob's signup/service identities, outbound agent personas); **never Stephen's human
  mail** (its own docs position it as "an API platform for giving AI agents their own inboxes"; no mobile
  app or IMAP documented).
- Experiment: do agent-owned addresses need a dedicated platform, or do provider aliases/Masked-Email
  cover it? Graduation: a real workflow (agent signups or an outbound persona) that aliases cannot serve.
  Kill: aliases suffice → close the account.
- Owner decision 2026-06-11: **key rotation deferred to the first step of L1** (acceptable only on the
  presumption the key is inactive; the leak is in git history). Rotation + session-doc redaction open L1;
  new key to OpenBao.
- Burden: none. Track: S/A experiment shelf.

### Mac resource layer (BlueBubbles, mlx-audio TTS, Obsidian/filesystem MCP servers, mlx-whisper)

- Category: Apple-silicon peripherals. **Decision: keep.** Target: Mac. State: minimal (BlueBubbles
  config).
- Purpose/outcome: iMessage → Elaine; quality TTS; vault access for the NUC gateways over tailnet MCP
  (`connect_timeout: 5`, graceful when the Mac sleeps).
- Backup: Mac is dotfiles/Time-Machine territory; homelab only documents the contracts. Test gates:
  iMessage round-trip; TTS smoke; MCP reachability with offline-degradation check.
- Burden: quarterly. Track: L1. Rationale: macOS-only capabilities; v11 §5.5 pattern carried.

______________________________________________________________________

## 2. Life automation applications

### Paperless-ngx

- Category: document management. **Decision: add** (the v12 anchor add). Default: Paperless-ngx pinned
  2.20.x (v3 beta has ~10 breaking changes; upgrade after v3 settles + exporter verified). Ranked
  alternatives: Docspell (smaller community), plain folders + OCR scripts (no workflow), Stirling-PDF
  (toolbox, not management; rejected as standing service).
- Purpose: ingest receipts/admin docs/letters via consume folder + mail rules (fed by Elaine: "file this
  receipt") + API; OCR; tagging; search.
- Primary outcome: kills the paper/admin executive-function tax; "find my lease" answered by an agent in
  seconds.
- AI/life value: high; agents query via REST API; documents become corpus. AI/devops value: low.
  Subscription value: avoids document-cloud SaaS.
- Target: NUC k3s. State: originals dir (**canonical**, untouched files) + Postgres (CNPG) + its own
  Redis (scoped dependency, not shared infra) + index (derived).
- Auth: Authelia forward-auth; API token in OpenBao. Backup/restore/export: originals via Restic (strict
  tier); nightly `document_exporter` (full round-trip: documents + metadata + DB) to canonical storage;
  monthly exporter re-import to scratch (layer 3). Export story is first-class (a key reason it won).
- Test gates: consume-folder ingest synthetic; OCR sanity; exporter freshness check.
- Migration gates: n/a (greenfield). Burden: monthly. Risk: contains sensitive documents; LAN-only, local
  OCR only (ADR-0003). Hardware fit: ~1.5GB + OCR CPU bursts. Dependencies: CNPG, Redis, Authelia,
  Restic.
- Track: L3. Rationale: GPL-3.0, very active (v2.20.15, 2026-04-27; aggressive issue triage), arm64
  images, docs-recommended modest hardware; the strongest export story in its category.

### Home Assistant

- Category: home automation. **Decision: keep** (integration target, not the center; brief's HA posture).
  Alternatives: openHAB (heavier, Java), Domoticz (dated).
- Purpose: entity/event hub; expose to Bob via the hermes HA toolset (read + notify first); 2-3 cautious
  automations (lights, reminders, presence nudges); events feed the morning brief.
- Target: NUC k3s; recorder on CNPG. Auth: Authelia (mobile-app path per v11 7.1 options); long-lived
  token in OpenBao.
- Backup/restore/export: `/config` PVC via Restic, quarterly restore; recorder rides Barman. Test gates:
  event → notification synthetic (layer 4); recorder write check.
- Autonomy: ADR-0006 tier 2, actuation allowlist excludes locks/security domains.
- Burden: monthly. Risk: physical-world actuation, bounded by allowlist. Fit: ~1.5GB. Track: H1-H2.
  Rationale: integration value without Zigbee theology; v11 design carried.

### ntfy

- Category: push notifications (**tertiary layer of the ADR-0014 chain**). **Decision: keep, replaced
  placement** (moves to the Pi). Purpose: the **Discord-independent** delivery path, paging when Discord
  itself (or the hermes/Discord account path) is the failure; not a second routine channel.
- Target: Pi (quadlet). State: minimal cache. Auth: access tokens; tailnet-only.
- Backup: config in repo; state expendable. Test gates: Gatus check; outage drill (F3: NUC off →
  secondary layer is Pi-Alertmanager → Discord webhook; Discord-path-down drill → ntfy still pages).
- Burden: none. Fit: ~50MB. Track: F3. Rationale: ADR-0001 placement test + ADR-0014 layering.

### Atuin sync server

- Category: dev QoL. **Decision: keep.** Target: NUC k3s (shares CNPG; avoids a second DB engine; Pi move
  noted as option if Atuin's SQLite mode is preferred later). Backup: rides Barman. Gates: sync
  round-trip from two machines. Burden: none. Track: A1-adjacent. Rationale: PLAN-ATUIN carried; client
  stays dotfiles.

### n8n (scoped)

- Category: workflow automation. **Decision: keep, scoped** to what hermes cron cannot do (OAuth'd
  third-party integrations, complex multi-step web flows). Alternatives ranked: hermes cron + scripts
  (first choice for anything it can do), Windmill (heavier, open-core), Huginn (aging), Activepieces
  (license similar caveat).
- License caveat: **fair-code (Sustainable Use License), not OSI**; acceptable for personal self-hosting;
  flagged per research discipline.
- Target: NUC k3s; CNPG-backed. Auth: Authelia + webhook token paths. Backup: DB via Barman; workflows
  exported to repo (canonical) on change.
- Test gates: workflow dry-run synthetic. Burden: monthly. Autonomy: tier-2 rules apply per workflow.
  Track: L2+. Rationale: carried from v11 with the same scoping; the license note makes the
  replace-by-cron bias explicit.

______________________________________________________________________

## 3. Knowledge and reading

### Karakeep (+ Meilisearch)

- Category: read-later/bookmarks. **Decision: keep** (core of the Readwise replacement, carried from
  v11). Alternatives: Readeck (lighter; revisit only if Karakeep bloats), Wallabag (dated UX).
- Purpose/outcome: capture-anything from iPhone/share-sheet; highlights to vault; feeds the knowledge
  corpus.
- Target: NUC k3s (web + Chrome worker amd64 + Meilisearch). State: saved content + DB (canonical-ish:
  content is the copy of record for dead links) + Meilisearch index (**derived, rebuild job**).
- Auth: Authelia; API key in OpenBao. Backup: DB via Barman; assets PVC via Restic (quarterly restore);
  Meilisearch rebuilt, never restored.
- Test gates: save-URL synthetic; search canary after rebuild. Burden: monthly. Fit: ~2.5GB. Track: L
  (carried). Subscription value: Readwise (~$9/mo) replacement completes here.

### FreshRSS

- Category: RSS. **Decision: keep.** Alternatives: Miniflux (fine; FreshRSS kept for API breadth +
  existing plan). Target: NUC k3s; CNPG. Backup: rides Barman; OPML export to repo monthly (canonical).
  Gates: feed-poll smoke; OPML export freshness. Burden: none. Track: L (carried).

### SearXNG

- Category: private metasearch (agent search backend). **Decision: add.** Alternatives: Whoogle
  (narrower), paid search APIs (metered, privacy).
- Purpose: give agents/web tools a private, key-free search endpoint; reduces metered search-API spend.
- Target: NUC k3s. State: `settings.yml` in repo only (stateless; limiter off for LAN-only). Auth:
  LAN/tailnet only, Authelia in front of the UI.
- Backup: none needed (config in repo). Test gates: query smoke; upstream-engine health. Burden:
  quarterly (rolling-release image bumps via Renovate). Risk: upstream engines may throttle; acceptable
  for low-volume private use (its own docs' honest caveat). Fit: \<0.5GB. Track: A5/L2. Rationale: AGPL,
  daily maintenance, stateless.

### Open Notebook

- **Decision: add**, owner request 2026-09-12. Self-host
  [lfnovo/open-notebook](https://github.com/lfnovo/open-notebook) for research notebooks, source-based
  questions and notes. Track: [L6](PLAN-v12.md#l6-open-notebook-research-workspace), after F1/F2.
- Target: NUC, application plus SurrealDB and persistent files. Use private authenticated access,
  approved model providers and scoped credentials; record any content sent to hosted models.
- Preserve canonical originals and exported notes in Obsidian or their owning source. Define the
  Hindsight boundary and optional handoff from Rust vpp (Voice Processing Pipeline).
- Backup: database, files and original provider encryption key. Gates: representative import,
  source-checked answer, usable export and isolated restore. Burden: monthly target, measured at setup.

### Obsidian vault + Syncthing

- Category: knowledge canonical store + sync. **Decision: keep.** The vault is canonical (ADR-0004);
  Syncthing mirrors Mac ↔ NUC for agent file access alongside the MCP path. Backup: git (Obsidian Git) +
  Restic. Gates: sync-conflict watch (the v11 two-writer note carried). Burden: quarterly.

______________________________________________________________________

## 4. AI/devops platform

### Forgejo (+ Forgejo Actions runner)

- Category: git forge + CI. **Decision: add** (platform spine). Default: Forgejo (v15.x line or v11 LTS;
  pinned). Ranked alternatives: Gitea (technically equivalent; rejected on stewardship: for-profit Gitea
  Ltd + open-core Enterprise), Woodpecker CI (runner-up CI; own YAML, breaks GitHub-Actions reuse),
  GitLab CE (an order of magnitude heavier).
- Purpose: mirror GitHub repos (homelab, dotfiles, projects); run CI (the layer-1 static suite +
  kubeconform + ansible checks) on push; host Renovate; receive **human-reviewed agent PRs** (ADR-0006:
  branch protection, no self-merge); OCI package registry for lab images.
- Primary outcome: every infra change is linted/validated before Stephen merges it; agents get a forge
  they can propose to without touching GitHub credentials.
- AI/life value: indirect. AI/devops value: the highest in the portfolio. Subscription value: none
  (GitHub free remains the public home; Forgejo is the lab mirror + CI).
- Target: NUC k3s. State: git repos (mirrors, re-cloneable) + SQLite/data dir. Auth: SSH over tailnet;
  web via Authelia; runner token in OpenBao.
- Backup/restore/export: **file-level backup of the data dir + repos via Restic** (the documented
  `forgejo dump` SQL-restore bugs make file-level the safe path); repos double-covered by GitHub mirrors;
  quarterly data-dir restore drill.
- Test gates: push → CI pipeline green synthetic; mirror freshness; registry push/pull smoke.
- Burden: monthly. Risk: low (tailnet-only). Fit: ~2GB incl. runner. Dependencies: none hard (SQLite).
  Track: A1-A2.
- Rationale: nonprofit stewardship (Codeberg e.V.), GPL-3.0+, LTS line, GH-Actions-compatible, official
  Renovate platform support, arm64 artifacts; same-day patch cadence observed (v15.0.3 + v11.0.15 on
  2026-06-10).

### Renovate (self-hosted, scheduled)

- Category: dependency automation. **Decision: add.** Alternatives: Dependabot (GitHub-only), manual (the
  status quo it fixes).
- Purpose: scheduled runs against Forgejo; opens PRs for chart/image/action/pip bumps; **human merges**
  (ADR-0006 tier 1 exemplar).
- Target: NUC (k3s CronJob). State: none (config in repos). Backup: n/a. Gates: PR-opened synthetic on a
  canary pin; rate-limited schedule.
- Burden: weekly *review* time, deliberately human; the bot itself none. Track: A3. Rationale: official
  Forgejo platform support; AGPL; converts upgrade toil into reviewable diffs.

### Langfuse

- Category: LLM tracing. **Decision: experiment** (not core). Why not core: v3 self-host is a 5-service
  stack (Postgres + ClickHouse + Redis + S3/MinIO + web/worker; official compose guidance is
  4-core/16GB-class), heavy for tracing three agents.
- Experiment hypothesis: the hermes langfuse plugin makes traces nearly free to emit; if weekly debugging
  of agent behavior uses them, it earns the footprint.
- Target: NUC k3s (experiment namespace). Graduation per backlog (incl. its own backup story: PG +
  ClickHouse + S3 trio). Burden if adopted: monthly+. Track: A5.

### LiteLLM proxy

- Category: LLM gateway/spend. **Decision: experiment** (weakest of the four; may be rejected). hermes
  already does fallback routing; LiteLLM adds central per-key budgets/spend at the cost of a Postgres
  dependency, a daily-release treadmill, and a new secret-holding component. MIT core + enterprise
  carve-out.
- Experiment hypothesis: one month of spend data changes a provider decision; otherwise reject and rely
  on provider dashboards + Langfuse.
- Target: NUC k3s (experiment). Track: A5.

### Ollama (CPU)

- Category: local model serving. **Decision: experiment** (utility tier only; ADR-0003). Use: embeddings
  beyond Hindsight's, small classifiers/tag suggesters for Paperless/Karakeep, async batch jobs. Never
  interactive agent inference (CPU tok/s; no official benchmark, uncertain).
- Target: NUC k3s or systemd. State: re-downloadable models (stateless story, cleanest of the AI adds).
  Burden: quarterly. Track: A5/L-support. MIT.

### Open WebUI

- Category: chat UI. **Decision: reject.** The interface is Discord/hermes (and Claude Code on the
  workstation); another chat surface is sprawl without a workflow it serves. Reconsider only if a
  local-model workflow needs a web UI.

______________________________________________________________________

## 5. Platform substrate (NUC)

### k3s (single node, embedded etcd, Cilium and Longhorn)

- **Decision: keep, changed back** (owner decision 2026-06-11 reversing ADR-0008: embedded etcd + Cilium
  KPR/LB-IPAM/L2 + Longhorn replica-1, version pinned; corrected v11 1.1b/1.1c is the spec).
  Alternatives: stock-k3s diet (the documented de-escalation path), SQLite datastore (reversal not worth
  it), Podman-only NUC (forfeits operators/learning).
- Backup/restore: scheduled etcd snapshots → B2; quarterly `--cluster-reset` scratch drill; etcd is
  objects-only, **not** a system backup (full rebuild = etcd → app restores).
- Gates: node Ready smoke; snapshot freshness; restore drill. Burden: quarterly (pinned upgrades,
  snapshot-before-upgrade). Track: F1.

### Traefik / cert-manager / ESO

- **Decision: keep** (single replicas; DNS-01 via scoped Cloudflare token, Ansible-Vault interim →
  OpenBao; ESO is the OpenBao→k8s secret path).
- Gates: IngressRoute cert smoke; cert-expiry alert; ExternalSecret sync canary. Burden: quarterly.
  Track: F1.

### CloudNativePG (single Postgres + pgvector)

- **Decision: keep** (`postgresql.cnpg.io/v1`, single instance, Longhorn PVC per the v11 owner decision
  (ADR-0008 reversed), Barman Cloud Plugin PITR → B2; B2 S3-compat proven by a real restore before
  reliance, v11 caveat carried).
- Consumers: Hindsight, Paperless, Karakeep, FreshRSS, n8n, HA recorder, Atuin, Authelia `storage:`,
  Actual? (no: Actual is SQLite-internal), Forgejo? (no: SQLite).
- Gates: `pg_isready` smoke; monthly PITR-to-scratch (the anchor restore drill). Burden: monthly. Track:
  F1.

### Cilium and Longhorn

- **Decision: core, reinstated** (owner decision 2026-06-11; ADR-0008 reversed). The corrected v11 design
  is the implementation spec (1.1b/1.1c, the policy surface boundary, L2-announce Beta caveats); the
  Cilium/Longhorn drills return to the testing layer; the stock diet remains the de-escalation path.

______________________________________________________________________

## 6. Edge/resilience appliance (Pi 5, 16GB, NVMe; systemd + Podman quadlets, never k3s)

### Pi-hole + Unbound (primary DNS) and the NUC secondary

- **Decision: keep** (Pi native primary; NUC k3s secondary pod; nebula-sync parity; router secondary
  points at the NUC instance, never a public resolver). Gates: dual-resolver dig smoke; blocklist parity
  check. Burden: quarterly.

### chrony (NTP master) and Tailscale subnet router

- **Decision: keep** (carried; chrony **re-promoted to hard Kerberos prerequisite** by ADR-0010's Track
  I). Gates: stratum check; Kerberos-skew assertion once I2 lands; subnet-route reachability from
  cellular. Burden: none.

### Prometheus, Loki, Grafana, Alertmanager (the observability stack)

- **Decision: keep, replaced placement** (NUC → Pi; ADR-0001). Single instances; quadlet units in the
  repo; arm64 images confirmed.
- State: TSDB/chunks on Pi NVMe (**derived telemetry**: best-effort retention, rebuild-not-restore;
  dashboards provisioned as code).
- Gates: NUC-off drill (F3): Grafana serves and the Pi Alertmanager delivers to Discord; a separate
  Discord-outage drill verifies ntfy; scrape-target completeness check. Burden: monthly. Rationale:
  monitoring that dies with the monitored host fails its one job.

### Grafana Alloy (log/metric shipping, both hosts)

- **Decision: replace** (Promtail is EOL 2026-03-02). Official converter migrates configs. Gates:
  log-line canary from each host appears in Loki. Burden: quarterly.

### Dozzle

- **Decision: add**, owner request 2026-09-12. Use [amir20/dozzle](https://github.com/amir20/dozzle) for
  live container-log inspection. Track: [F5](PLAN-v12.md#f5-dozzle-live-container-logs), after F1.
- Target: supported Kubernetes mode on the NUC; verify Pi/Podman coverage separately. Private
  authenticated access with minimum log permissions; terminal and container actions stay disabled.
- Alloy/Loki retain the archive and alerting role. Back up viewer configuration and verify a rebuild,
  representative log access and denied unauthenticated access. Burden: quarterly target, measured.

### Gatus (synthetic checks)

- Category: smoke-test harness. **Decision: add.** Alternatives: Uptime Kuma (click-configured; Gatus
  wins on config-as-code in the repo).
- Purpose: layer-2 of the pyramid as a *service*: every core endpoint, auth path, cert, DNS answer
  checked continuously; alerts via Alertmanager/ntfy.
- Target: Pi. State: config in repo. Gates: it is the gate. Burden: none after setup. Track: F1+ (checks
  accrete per service).

### restic rest-server (append-only second repo)

- **Decision: keep, promoted** (v11 optional → v12 core; the Pi NVMe removes the old excuse). Target: Pi.
  Purpose: on-site immutable-ish copy completing 3-2-1 with B2; survives NUC loss and B2 account
  compromise (append-only).
- Gates: monthly alternate-source restore (B2 ↔ Pi); append-only enforcement test (delete refused).
  Burden: quarterly.

### Healthchecks.io heartbeat + heartbeat-overdue consumer

- **Decision: keep (external SaaS dead-man) + add (the Pi consumer)** closing the cross-host
  machine-death gap from the osquery v2 design (ADR-0009). Self-hosting Healthchecks: reject (defeats the
  external dead-man purpose).
- Gates: stop the heartbeat → external page within ~10 min; silence a host → Pi consumer pages. Burden:
  none.

______________________________________________________________________

## 7. Identity and secrets (ADR-0005 superseded by ADR-0010)

### OpenBao

- **Decision: keep** (single-node Raft on NUC, seal "static" with boot-staged tmpfs key, two audit
  devices, hourly snapshots; the **dresden → lash migration is scheduled as F1.4**). De-escalation path
  documented: SOPS+age if the API stops earning its keep.
- Gates: unseal-after-reboot check; ESO sync canary; monthly snapshot-restore drill. Burden: monthly.
  Risk: the crown jewels; tailnet/LAN-only, audited.
- A6 selects Infisical for agent credentials. Reconcile agent consumers and the F1.4 inventory before
  migration; each credential must have one authoritative store.

### Infisical Secrets Management + Agent Proxy

- **Decision: add**, owner request 2026-09-12. Self-host for Claude Code, Codex and Hermes, including
  nicodemus. Full scope and acceptance checks:
  [Track A6](PLAN-v12.md#a6-self-hosted-infisical-for-agent-credentials).
- Target: Infisical on the NUC, private HTTPS over the existing Tailscale network; choose a separate
  Agent Proxy host from agent runtimes before deployment. Homelab owns services, policies, networking and
  recovery; dotfiles owns clients, non-secret harness configuration and uu upgrades.
- Access: separate human and machine identities; agents use approved services through an isolated proxy
  without raw-secret read permission. Verify self-hosted licensing for every required control.
- Personal passwords remain in KeePassXC/Strongbox; Infisical holds only credentials selected for agents,
  preferably separate accounts or restricted tokens. A shared personal login needs a copy in both stores
  and an explicit rotation/update procedure, without automatic synchronization.
- Roaming laptops launch agents through the Infisical command-line client's `agent-proxy connect` command
  over Tailscale. Everyday iPhone access and offline passwords stay with Strongbox; its optional
  Infisical dashboard access is for administration. The S1 client trial remains deferred and independent.
  Resolve OpenBao overlap before moving agent secrets.
- Backup: PostgreSQL, Redis, configuration and original encryption key in the existing backup system,
  with independent bootstrap recovery. Gates: isolated restore, roaming-device access, denied raw reads,
  destination restrictions, lost-device revocation, home-outage behavior and no secret values in agent
  output. Burden: monthly plus security updates. Track: A6, after F1/F2.

### Authelia (file-backend bootstrap → LLDAP backend)

- **Decision: keep, changed** (bootstraps on the file backend with argon2id, which breaks the v11
  ordering cycle and remains the tested de-escalation path; upgrades to the LLDAP backend in Track I per
  ADR-0010; OIDC where apps support it, noting provider is upstream-beta). Runner-up: Pocket ID (passkey
  OIDC; rejected for now: no forward-auth half).
- Gates: SSO login synthetic incl. TOTP; regulation lockout check; post-I1, login resolves against LLDAP.
  Burden: quarterly.

### Ansible Vault + KeePassXC (+ kdbx canonical)

- **Decision: keep** (bootstrap-only / human master store respectively; unchanged roles). kdbx is
  canonical (ADR-0004) and the Strongbox/KeePassium question is purely a client choice (Track S1,
  deferred under the September KeePassXC/Strongbox decision). KeePassXC additionally holds the Track I
  realm material (KDC master key/stash copies).

### LLDAP

- Category: user directory. **Decision: keep (restored by ADR-0010; Track I).** Purpose: one directory
  feeding Authelia + SSSD. Primary outcome: enterprise-IAM operating experience + real SSO semantics
  across the lab.
- Target: NUC k3s, single instance over CNPG (stateless, shared `LLDAP_KEY_SEED`; corrected v11 3.1
  design). Auth: admin UI behind Authelia; bind password in OpenBao.
- Backup/restore/export: rides Barman PITR (covered by the monthly drill); Authelia's file backend is the
  outage fallback. Test gates: `ldapsearch` smoke; Authelia-against-LLDAP login synthetic.
- Burden: monthly (Track I budget). Risk: low (LAN-only). Dependencies: CNPG, OpenBao. Track: I1.
- Rationale: ADR-0010; classified as learning/SSO breadth, not a defense layer.

### Kerberos KDC (+ optional kpropd slave on the Pi 5)

- Category: system auth. **Decision: keep (restored by ADR-0010; Track I).** Purpose: ticket-based
  host/service auth; the AD-model half of the learning goal. Master on the NUC with its **own db2 store**
  (never LLDAP-backed; v11 correction stands); optional read-only slave on the Pi 5 so existing-principal
  auth survives NUC maintenance.
- Target: NUC (+ Pi option). State: db2 principal DB + stash. Auth/secrets: master key + stash copies in
  KeePassXC; keytabs distributed by Ansible from vaulted material.
- Backup/restore/export: **nightly `kdb5_util dump` → canonical storage + Restic; quarterly restore into
  a scratch realm** (the row v11 lacked). Test gates: `kinit` smoke; GSSAPI ssh host-to-host; chrony-skew
  assertion (chrony re-promoted to hard prerequisite).
- Burden: monthly, budgeted as tuition. Risk: lockout-class failure modes; mitigated by the break-glass
  gate below. Dependencies: chrony, LLDAP (identity only), Ansible. Track: I2/I4.
- Rationale: ADR-0010 learning outcomes (realm ops, keytab/stash lifecycle, kprop replication).

### SSSD (Linux hosts; dresden via dsconfigldap + Heimdal)

- Category: PAM/NSS client layer. **Decision: keep (restored by ADR-0010; Track I).** Purpose: Kerberos
  auth + LLDAP identity on lash and the Pi, with local caching for outage tolerance; macOS cannot run
  SSSD (carried v11 finding).
- Backup: config in repo (rebuildable). Test gates: `id <user>` resolves LLDAP groups; ticket login
  works; **break-glass local login proven with SSSD stopped** before any `AllowGroups` tightening
  (carried v11 gate).
- Burden: monthly (Track I). Track: I3. Rationale: ADR-0010; completes the enterprise triad.

______________________________________________________________________

## 8. Security floor and telemetry (ADR-0009)

### NetBird

- **Decision: add**, owner request 2026-09-12. Plan self-hosted
  [netbirdio/netbird](https://github.com/netbirdio/netbird) under
  [F4](PLAN-v12.md#f4-netbird-remote-access). Resolve publicly reachable control/relay hosting against
  the home connection limits and record its cost before selecting a host.
- Preserve working Tailscale access until a reviewed migration passes; Headscale remains deferred. Map
  policies, private name resolution, routes, device revocation and recovery before cutover.
- Homelab owns server deployment, policies and state backups; dotfiles owns laptop clients and updates.
  Gates: roaming Mac/iPhone access, Infisical connectivity, denied access, lost-device revocation,
  restore and rollback. Burden: monthly target, measured. Infisical remains the credential broker.

### Network segmentation: guest + Media/IoT VLANs (UniFi gateway/switch/AP configuration)

- Category: network security floor. **Decision: add** (ADR-0011 + its casting amendment; first item in
  F0). Not a homelab service: configuration of the **owned UniFi Dream Router (UDR), the only network
  gear actually owned** (the UCG-Fiber/QNAP/U7 in `docs/hardware/` are planned purchases); documented in
  the repo for reproducibility. The UDR's 4 LAN ports cover NUC + Pi + wired TV + spare; wireless rides
  SSID-per-VLAN.
- Purpose: guests regularly join the home Wi-Fi and **need to cast to the TV** (movie nights). Three
  segments: isolated guest VLAN (client isolation, internet-only, optional Pi-hole :53 flow); a
  **Media/IoT VLAN** holding the TV with mDNS reflection guest↔media + a narrow guest→TV cast-port
  allowance; the homelab VLAN untouched by either.
- Primary outcome: the named live LAN threat (a guest device inside the house) loses its path to the k3s
  API, VIPs, webhooks, and every other homelab listener, while movie-night casting just works.
  Homelab→media stays open (Stephen casts; HA integrates the TV for Track H); media→homelab denied.
- Backup/restore/export: UniFi controller backup + the documented layout in-repo. Test gates: **from the
  guest VLAN: internet works, the TV is discoverable and castable, every homelab IP/port is unreachable
  except the explicitly enabled Pi-hole port 53 allowance, if selected; nothing else on the media VLAN
  answers; from the media VLAN: the homelab subnet is unreachable**; homelab SSID passphrase rotated if
  guests ever held it.
- Burden: none after setup. Risk: misconfiguration; mitigated by the second layer below (host grants by
  named IP). Dependencies: none. Track: F0.

### nftables, sshd hardening + break-glass, LUKS, Tailscale ACLs + Tailnet Lock, unattended-upgrades, fail2ban

- **Decision: keep** (the floor; v11 designs carried with the Cilium port set restored (ADR-0008
  reversed) and **sources tightened by ADR-0011: grants to named homelab host IPs, never the whole /24**,
  since segmentation can be misconfigured and the host firewall no longer assumes it wasn't). Each layer
  names its attack: nftables (LAN lateral movement, now incl. a hostile device that lands on the homelab
  VLAN), sshd+keys (credential stuffing), LUKS (physical theft), ACLs/Lock (tailnet device compromise),
  upgrades (known CVEs), **fail2ban (auth-abuse throttling from a compromised tailnet or VLAN peer;
  restored by ADR-0010 with `ignoreip` scoped to named admin sources, not CIDRs, so the layer keeps its
  meaning)**.
- Gates: `nft list ruleset` assertions in CI (rendered config), ssh-deny checks, Lock signature prompt
  test, fail2ban jail-active + scoped-`ignoreip` assertion. Burden: quarterly.

### auditd (trimmed) → Loki

- **Decision: keep** (kernel-level complement; rate-limited ruleset per v11 0.8.5). Gates: events/sec
  within Loki budget. Burden: quarterly.

### osquery two-tier pipeline (Mac as-built; Linux port)

- **Decision: keep + add (Linux port)** per ADR-0009. Mac stays chezmoi-owned until hermes relocates (the
  design's own trigger); Linux packs/Ansible + the Pi heartbeat consumer are homelab-owned.
- Gates: synthetic page-tier event reaches Discord; watchdog liveness; per-route HMAC verified. Burden:
  monthly. Track: F3+.

### UniFi Threat Management (gateway IDS/IPS)

- Category: network security. **Decision: add** (ADR-0013; configuration of the **owned UDR**, not a
  homelab service). Network-level inspection at the gateway where all LAN/guest/WAN traffic flows; the
  base this lab never had (Wazuh would not have provided it either).
- Default: enable the included Threat Management tier, **verifying on-device that the UDR supports it and
  measuring the throughput cost** (2GB RAM / dual-core gateway; acceptable if the ISP plan sits below the
  post-IPS rate). **CyberSecure by Proofpoint ($99/yr; price verified on the UCG-Fiber page, UDR
  availability verify-at-setup)** is the optional enhanced-signature upgrade. Detection-first; enable IPS
  blocking per category deliberately. Fallback if the UDR cannot carry it: the rest of the ADR-0013
  bundle stands, and the planned UCG-Fiber upgrade is the full-rate path (no Suricata-on-Pi: no managed
  switch, no mirror port).
- Backup/export: gateway config in the UniFi backup + layout documented in-repo (with ADR-0011's VLANs).
  Test gates: threat events visible via unpoller in Loki; alert path to Discord proven. Burden: quarterly
  (firmware + signature review). Track: F3.

### unpoller (UniFi telemetry exporter)

- Category: security/network telemetry. **Decision: add.** Target: Pi (quadlet). Exports UniFi metrics +
  IDS/threat events to Prometheus/Loki so gateway detections ride the standard Alertmanager → Discord
  path and the Grafana Security folder.
- State: none (config in repo; read-only UniFi credential from OpenBao). Test gates: scrape freshness.
  Burden: none. Fit: tiny. Track: F3.

### Trivy (CVE scanning, jobs not daemons)

- Category: vulnerability visibility. **Decision: add** (ADR-0013). (a) Forgejo CI: image/IaC scan on
  push, failing builds on critical CVEs (Track A2). (b) Scheduled rootfs/package scans on NUC + Pi →
  weekly CVE digest to Discord via hermes.
- State: none. Test gates: CI gate active; weekly digest freshness. Burden: the digest review itself (by
  design). Alternatives: Grype (comparable; Trivy chosen for images+IaC+rootfs in one tool). Track:
  A2/F3.

### Lynis (CIS-style hardening audit)

- Category: SCA/configuration scoring. **Decision: add** (ADR-0013). Monthly cron per Linux host;
  hardening-index report archived to canonical storage + digested to Discord. Alternative: OpenSCAP
  (rejected: enterprise-profile weight).
- State: reports (canonical files). Test gates: monthly report freshness. Burden: monthly digest review.
  Track: F3.

### Wazuh

- **Decision: defer** (experiment shelf; trigger: 3+ Linux hosts or a need the ADR-0013 bundle
  demonstrably fails to meet; spec: corrected v11 §3.12; official floor 4 vCPU/8GiB acknowledged). Its
  bases are covered meanwhile by the ADR-0013 map (UniFi TM + unpoller + Trivy + Lynis + the Grafana
  Security folder). CrowdSec: **reject carried** (no public surface to defend).

### Mouse (sandboxed LLM second-opinion on CRITICAL alerts)

- **Decision: experiment, deferred.** Hermes owns this sandboxed investigator, restricted to Critical
  alerts. Its advisory follows the original alert and never gates or delays delivery. Keep the existing
  investigation design and dotfiles task 24 coordination; this publication starts no investigator.

______________________________________________________________________

## 9. Backup tier

### Restic + Backblaze B2 (+ Object Lock, Governance mode) + Pi rest-server

- **Decision: keep** (Governance-mode lock + key-capability hygiene carried from v11; Pi repo promoted).
  3-2-1: live (NUC) / Pi NVMe append-only / B2 off-site.
- Gates: nightly success pings (distinct from liveness); monthly restores alternating source;
  lock-enforcement test (delete refused). Burden: monthly (drills are scheduled attention, by design).

______________________________________________________________________

## 10. Subscription replacement trials (ADR-0007 gates; see backlog for full experiment cards)

### Actual Budget (replaces YNAB) [strict class]

- **Decision: experiment.** Default: Actual (MIT, v26.6.0 2026-06-01, monthly cadence; envelope-faithful;
  zip export = SQLite + metadata, re-import first-class; YNAB importers; arm64). Ranked: Firefly III
  **rejected** (its own docs warn its export "may not restore everything" and its author rejects
  zero-based budgeting; both disqualifying for this use), GnuCash (not a budgeting workflow).
- Bank feeds: manual OFX/QFX/CSV always works; SimpleFIN bridge optional ($1.50/mo, a *paid relay*, noted
  honestly).
- Target: NUC k3s; SQLite-internal; nightly zip export → canonical + Restic. Auth: Authelia + its own
  password; tailnet-only.
- Migration gates (strict): YNAB import verified; 60-90d dual-entry reconciling; restore + rollback
  demonstrated **before** cutover; go/no-go note; final YNAB export archived. Burden during trial: weekly
  (accepted, time-boxed). Track: S2.

### KeePassium (deferred client trial) [standard class, strict data]

- **Decision: defer** under the September instruction to retain KeePassXC/Strongbox. Reopen only with
  explicit approval. The earlier proposal was a client swap on the same kdbx, with no server. GPLv3;
  active (2026-05); one-time Pro if free-tier limits chafe (uncertain: FaceID/OTP tier placement
  unverified).
- Why: Strongbox post-acquisition signals (repo stale since 2025-11-05, founder advisory-only) justify
  de-risking; Vaultwarden **rejected** (abandons kdbx-canonical, adds an always-on secrets server +
  client-compat coupling).
- Migration gates: 30-day parallel (both clients on the same kdbx, which is the rollback); AutoFill
  verified. Track: S1.

### Immich (replaces Google Photos) [standard, privacy-weighted]

- **Decision: experiment, gated on the 4TB SSD.** Mature since v2.0.0 (2025-10-01; v2.7.x current);
  official 6GB-min requirement; built-in daily DB dumps + originals-are-files model fits ADR-0004; ML on
  CPU acceptable (smart search batch).
- Migration gates: 60-day parallel; mobile background-backup proven (iOS scheduling uncertainty noted);
  restore demonstrated (DB dump + originals). Track: S3.

### Vikunja (would replace Todoist) [standard]

- **Decision: experiment, not scheduled** (keep Todoist). Vikunja is the only credible analogue (v2.3.0,
  AGPL, Todoist OAuth importer, full ZIP export) but CalDAV is self-described alpha with iOS listed
  broken, and the td-CLI investment is deep. Reconsider at Vikunja 3.x / CalDAV maturity.
  Donetick/Habitica: **reject** (wrong problem / not self-host-focused). Radicale: **defer** (if CalDAV
  serving is ever wanted, it beats Baikal on cadence + flat-file storage).

______________________________________________________________________

## 11. Deferred and rejected (compact)

| Item                                            | Decision                                        | One-line rationale                                                  | Reconsider when                                          |
| ----------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------- |
| Wazuh                                           | defer                                           | 8GiB floor + OpenSearch discipline for 3 hosts; osquery path covers | 3+ Linux hosts or CVE/SCA need                           |
| OpenAleph                                       | defer (unchanged)                               | own future NUC; PLAN-v8 §10 is the spec                             | second NUC purchased                                     |
| v8 5-node HA scale-out                          | defer (unchanged)                               | aspirational fleet                                                  | Pis join as agents                                       |
| Headscale                                       | defer                                           | self-hosted control plane = new SPOF; free tier suffices            | Tailscale pricing/policy change                          |
| Cilium / Longhorn                               | core, reinstated 2026-06-11 (ADR-0008 reversed) | n/a, day-one Track 0                                                | corrected PLAN-v11 1.1b/1.1c + drills                    |
| Hermes sandboxed investigator (Mouse reference) | experiment (deferred)                           | Critical-only advisory after the original alert                     | existing investigation design and dotfiles task 24 gates |
| Radicale / CalDAV serving                       | defer                                           | Google Calendar acceptable; Radicale wins the category if wanted    | calendar self-host prioritized                           |
| CrowdSec                                        | reject (carried)                                | no public surface                                                   | broader ingress added                                    |
| Firefly III                                     | reject                                          | anti-envelope by design; export warns against itself                | n/a for budgeting                                        |
| Vaultwarden                                     | reject                                          | breaks kdbx-canonical; adds a secrets server                        | kdbx model abandoned (unlikely)                          |
| Donetick, Habitica                              | reject                                          | wrong problem / licensing+stack                                     | n/a                                                      |
| Stirling-PDF                                    | reject as standing service                      | run ad-hoc when needed; Paperless covers OCR                        | recurring PDF-toolbox need                               |
| Open WebUI                                      | reject                                          | interface sprawl                                                    | local-model UI workflow emerges                          |
| Self-hosted Healthchecks                        | reject                                          | external dead-man must be external                                  | n/a                                                      |
| Gitea, Woodpecker                               | reject / runner-up                              | stewardship / non-GHA syntax                                        | Forgejo falters                                          |
| GHA gha-watcher relocation                      | undecided                                       | respect in-flight dotfiles plan                                     | hermes lands on NUC                                      |
