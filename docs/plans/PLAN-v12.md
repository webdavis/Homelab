# PLAN-v12

Derived from **PLAN-v11** (v10 → v9 → v8 lineage). v12 keeps its coverage matrices and restore gates
while prioritizing ADHD/life automation and an AI-assisted engineering platform. Subscription replacement
supports those goals.

## Publication scope and current decisions (2026-09-13)

Task 68c publishes this plan, its service matrix and experiments backlog only. Services, migrations,
trials and acceptance checks described below remain planned unless separately evidenced. Publishing these
documents does not start them. The June research, version pins, prices and descriptions of local state
are retained snapshots and require fresh verification before implementation.

Supporting PLAN-v11 and earlier plans, `PLAN-OPENBAO.md`, `PLAN-ATUIN-SERVER.md`, `PLAN-RSS-FEED.md`, the
architecture decision records (ADR-0001 through ADR-0014) under `docs/adrs/`, and the hardware inventory
remain unpublished local work outside this publication. References to them identify pending source
dependencies. Publish and review the required source before using a dependent section as an
implementation specification.

The September operator decisions take precedence over the retained June discussion:

- Personal passwords stay in KeePassXC/Strongbox. S1 is deferred pending an explicit decision to reopen
  the client trial. Infisical is selected for credentials intentionally made available to agents.
- Homelab owns Infisical (A6), NetBird (F4), Dozzle (F5) and Open Notebook (L6) service planning;
  dotfiles owns laptop configuration and managed client updates. Tailscale stays until a verified NetBird
  cutover. No Nix migration of either repository, macOS configuration or secrets is authorized.
- vpp (Voice Processing Pipeline) owns its Rust application. Calendar, Todoist, Bob and Open Notebook are
  optional integrations; ordinary notes must remain usable without them. Bob/Forzare starts after the
  full dotfiles modernization, including SP8. The Track L roadmap does not advance that work.
- Hermes owns the sandboxed investigator for Critical alerts only. Its advisory follows the original
  alert and never gates or delays it; the retained Mouse experiment refers to this same investigation.

Companion artifacts (new in v12):

- `PLAN-v12-service-matrix.md`: every service and candidate with decision, alternatives,
  backup/restore/export, test gates, and rationale.
- `PLAN-v12-experiments-backlog.md`: the experiment queue with explicit graduation criteria.
- `docs/adrs/`: ADR-0001 through ADR-0014, the stable record of the major decisions; this plan cites them
  rather than re-arguing them.

Owner addition, 2026-09-12: Track A6 adds self-hosted Infisical for agent credentials, including remote
laptop access and an iPhone access check. Personal passwords remain in the existing KeePassXC and
Strongbox workflow. A6 must reconcile the OpenBao overlap before migrating any credentials.

### What changed from v11 (read this first)

1. **The north star is stated and enforced.** v11 was a fleet-grade security/identity platform with a
   life-automation payload bolted on at Phase 5. The Pass-1 census: ~18 components existed to secure and
   operate 2 Linux boxes + 1 Mac for 1 human, vs ~13 that improve daily life, and the heavy half owned
   the earliest phases. v12 inverts the sequencing (life value in weeks, hardening as a parallel track)
   and prices **operator attention** as the scarcest resource: every service now carries an
   attention-cost class, and weekly-care services must justify themselves against the north star.
1. **The Pi is a Raspberry Pi 5 with 16GB RAM and an NVMe SSD** (the hardware docs confirm two are owned,
   with M.2 HATs). v11 assumed a Pi 4B 4GB on microSD in at least 8 load-bearing places. The Pi is now
   the **resilience/edge appliance** (ADR-0001): DNS, NTP, tailnet subnet router, **the whole
   observability stack (Prometheus, Loki, Grafana, Alertmanager), ntfy, Gatus synthetics, the restic
   append-only second repo (promoted from optional to core), the Healthchecks heartbeat, and the
   cross-host heartbeat-overdue consumer**. Placement test: everything needed to notice, page about, and
   diagnose a NUC outage must survive a NUC outage. `microsd_lite` is retired; the Pi runs native systemd
   \+ Podman quadlets, never k3s.
1. **Substrate: the v11 substrate is reinstated by owner decision (2026-06-11), reversing ADR-0008's
   diet.** k3s on the NUC runs embedded etcd, Cilium (kube-proxy replacement, LB-IPAM, L2 announcements)
   and Longhorn (`defaultReplicaCount: 1`, Postgres data included per the v11 decision), version-pinned,
   with the corrected v11 designs (1.1b/1.1c, the policy surface boundary, the Cilium and Longhorn
   drills) as day-one Track 0 work. The k8s networking/storage learning value was judged worth the
   roughly doubled Track 0 scope; the stock-k3s diet stays documented in ADR-0008 as the de-escalation
   path.
1. **Identity stack kept as a deliberate defense-in-depth + devsecops learning investment (ADR-0010,
   superseding ADR-0005's rejection after owner review).** Kerberos KDC (db2 store, optional kpropd slave
   on the Pi 5), LLDAP, SSSD, and fail2ban (with *scoped* `ignoreip`: named admin sources, not whole
   CIDRs) all stay, with guardrails: the work runs on its own Track I, may never block the
   life-automation spine, gets full backup/test parity (the KDC db2 dump drill v11 lacked), and is
   honestly classified (fail2ban = a thin real depth layer; the Kerberos trio = enterprise-IAM
   skill-building, not depth). Authelia bootstraps on the file backend (the cycle-breaker) and upgrades
   to the LLDAP backend. OpenBao + Ansible Vault + KeePassXC unchanged. ADR-0005's simplification remains
   the documented, break-glass-tested de-escalation path.
1. **Wazuh is deferred, and its bases are explicitly covered (ADR-0009 + ADR-0013).** The osquery
   two-tier pipeline (matching Stephen's own 2026-06-09 osquery v2 design, which defers Wazuh in its own
   text) + auditd cover host detection; the **ADR-0013 coverage map** closes the rest at near-zero
   standing cost: **UniFi Threat Management on the owned UDR gateway** (network IDS/IPS, which Wazuh
   never provided anyway; support + throughput cost on the UDR's 2GB/dual-core hardware is
   verify-on-device, with the planned UCG-Fiber upgrade as the full-rate path; CyberSecure $99/yr
   optional), **unpoller** feeding gateway threat events into the Pi's Prometheus/Loki, **Trivy** (CI
   image/IaC scans + weekly host CVE digests), **Lynis** (monthly CIS-style hardening scores), and a
   **Grafana Security folder** as the rarely-opened dashboard. Linux osquery is ported via homelab
   Ansible; the Pi runs the off-host heartbeat consumer; the "Mouse" LLM second-opinion agent stays a
   deferred experiment with its invariant intact (an LLM never gates the page tier).
1. **Promtail is EOL (2026-03-02, per Grafana's docs); log shipping is Grafana Alloy** everywhere, with
   the official one-command config converter as the migration path.
1. **The portfolio gains life-automation and platform weight:** Paperless-ngx (document/life-admin
   ingest), Forgejo + Forgejo Actions + Renovate (the AI/devops platform spine), SearXNG (private agent
   search), Gatus (synthetics), Actual Budget (strict-class YNAB trial), KeePassium (deferred client
   trial, kdbx canonical). Immich, Langfuse, LiteLLM, Ollama, Vikunja enter as gated experiments.
1. **Knowledge/data architecture is now explicit (ADR-0004):** canonical files, rebuildable derived
   stores, first corpus = homelab + dotfiles repos into a `homelab-knowledge` Hindsight bank, agents must
   cite canonical paths.
1. **Autonomy boundary is now explicit (ADR-0006):** software-dev agents are human-supervised (PR/doc
   proposals only); non-code automations may run autonomously when observable, reversible, and gated; the
   first autonomous category is data/knowledge automation.
1. **Cutover gates are now explicit (ADR-0007):** seven proof gates, with a strict class for
   finance/secrets (60 to 90 day parallel runs, demonstrated restore and rollback before cutover).
1. **Discord is the single notification pane (ADR-0014).** Every alert, digest, and agent communication
   routes to Discord via hermes; layered fallbacks keep even outage paging in Discord (the Pi's
   Alertmanager posts to a Discord webhook directly when the NUC/hermes is down), with ntfy demoted to
   the Discord-independent last resort and Healthchecks as the external dead-man. Native per-app
   notifications are disabled where possible; Todoist, the email app, and the security dashboard are
   drill-down surfaces reached by deep links, opened rarely.
1. **Email is two-plane, with a webhook-native routing layer on trial (ADR-0012 + Amendments 1-2):**
   Google Workspace Gmail is the incumbent mailbox/app (canonical, always directly accessible) but no
   longer assumed permanent; the routing layer, not the mailbox, provides webhooks. **Forward Email**
   (verified: native alias-to-webhook delivery + simultaneous mailbox forwarding) is trialed in stages,
   `agent.webdavis.io` MX first (zero risk), apex MX second (gated), replacing the Cloudflare Worker
   layer with one provider feature and feeding clawmail the AgentMail-style POSTs it was built for. Gmail
   push/Pub-Sub is re-graded to a viable non-default Wiring C (Amendment 4: scripted daily watch()
   renewal is the documented usage; ping-payload + GCP apparatus keep it non-default); Proton is
   un-rejected as a mailbox candidate via headless Bridge (Amendment 3, experiment S6); Fastmail drops to
   the second mailbox candidate (verified not webhook-native, which no longer matters); AgentMail stays
   scoped to agent-owned inboxes. **Ownership boundary (2026-06-11): homelab deploys the clawmail service
   and the cloudflared tunnel (stable public ingress endpoint); all routing-layer mechanics are the
   clawmail project's domain, swappable behind the tunnel URL since clawmail is sender-agnostic; homelab
   consumes the pinned payload contract** (ADR-0012 records the architecture; execution lives in the
   clawmail repo).

Carried forward unchanged from v11 unless restated here: the CGNAT/private-mesh model with the single
clawmail ingress (re-classified private-to-Stephen, ADR-0002), the hermes-agent runtime
(Bob/Elaine/Sierra, no Anthropic), Hindsight memory on Postgres+pgvector, Sierra's hard isolation (v11
§5.13), the clawmail tunnel design (v11 §2.7), the NUC↔Mac remote-MCP pattern (v11 §5.5), and the B2
backup discipline.

______________________________________________________________________

## Pass 1: critique of PLAN-v11

### 1. Strengths (kept)

- **Restore discipline:** Barman PITR with a mandatory scratch-cluster restore gate, OpenBao snapshot +
  rehearsed `restore -force`, etcd `--cluster-reset` drills, B2 Object Lock enforcement-point
  verification, and the "a backup that has never been restored is not a backup" rule. v12 carries all of
  it.
- **Source-verified engineering:** the v11 review fixed real deploy-breakers (pod→host webhook paths,
  single-node OpenSearch correctness) before any deployment. The method survives; v12 was built the same
  way.
- **The agent layer design** (hermes profiles, Hindsight banks, clawmail contract, Sierra's sandbox, the
  Mac-resource MCP bridge) is the most valuable part of the plan and is untouched.
- **Honest SPOF framing:** "lash down = recovery from backup, not failover" is correct and stays.

### 2. Contradictions and stale assumptions

- **Pi 4B 4GB/microSD assumptions in ≥8 places** (hostnames table, diagram, `microsd_lite`, "RAM budget
  tight", the 4GB Phase-9 gate, rest-server "if spare storage", optional heartbeat placement, "Pi 5 ...
  no production fit today") vs the actual Pi 5 16GB + NVMe. All rewritten by ADR-0001.
- **The LAN modeled as the trusted plane** vs the reality that guests regularly join the home Wi-Fi on
  the same subnet. Every "allow from `192.168.1.0/24`" rule silently included untrusted visitor devices.
  Fixed by ADR-0011: guest VLAN segmentation joins the security floor, and host-firewall grants tighten
  from the /24 to named host IPs.
- **Network gear: owned vs planned conflated** (a trap `docs/hardware/` sets and v12's own first pass
  fell into). The only owned network device is the **UDR**; the UCG-Fiber gateway, QNAP managed switch,
  and U7 Pro XG are planned purchases. The UDR carries the full ADR-0011 segmentation (VLANs, SSIDs, 4
  LAN ports: NUC, Pi, wired TV, spare); ADR-0013's gateway IDS gets verify-on-device caveats for the
  UDR's CPU class, with the planned gateway upgrade as the full-rate path.
- **Promtail everywhere** vs Promtail's EOL on 2026-03-02. Replaced by Alloy.
- **hermes state path mismatch:** v11 3.10 backs up `/var/lib/hermes/*` while Phase 5 puts state under
  `~/.hermes` per profile. v12's backup table fixes the path and adds `auth.json`/`state.db`/`jobs.json`
  to the restore test.
- **PLAN-OPENBAO.md (dresden, file storage, Shamir, AppRole) vs v11 3.4b (lash, Raft, static seal):** v11
  said "reconcile" but never scheduled the migration. v12 schedules it (Track 0, step F1.4) with the kv
  re-load procedure PLAN-OPENBAO already designed.
- **Superseded docs can be mistaken for current:** PLAN-URIEL-SERVICE-LAYOUT-v1 and the 2026-05-14
  session summary describe dead worlds (5-Pi, OpenClaw, Anthropic). v12 adds a superseded-documents list
  below. The session summary also contains what looks like a live AgentMail API key; **rotate it**
  (action item, human).
- **Cilium L2 (Beta) + the policy program** were marketed as a settled substrate; the review record shows
  they were the largest source of correctness findings. Resolved by ADR-0008, then reversed by owner
  decision (2026-06-11): the learning value won, and the corrected v11 spec is day-one work.

### 3. Overlap and unnecessary complexity

- **Four access-control planes** (nftables, Cilium default-deny, Tailscale ACLs, Authelia) plus Wazuh
  detection for a 2-node lab with one self-filtering ingress. The initial critique proposed dropping pod
  east-west controls. The 2026-06-11 decision reinstates Cilium and its policy surface alongside the host
  firewall, mesh access controls and web authentication; Wazuh remains deferred.
- **Kerberos/LLDAP/SSSD** duplicate what SSH keys + Tailscale ACLs already provide as *access control*;
  the critique stands as analysis. After owner review they are kept anyway as a defense-in-depth posture
  and enterprise-IAM learning investment, with guardrails and honest classification (ADR-0010).
- **Longhorn's headline feature (volume mobility) on a permanently single node**; local-path + per-app
  backup is strictly simpler (ADR-0008). Owner decision (2026-06-11) reinstated Longhorn anyway (question
  1: learning value; ADR-0008 reversed).
- **Wazuh vs the already-built osquery pipeline:** two detection stacks for three hosts (ADR-0009).
- **fail2ban on a tailnet-only SSH surface:** v11's own text demoted it to log generation. v12 keeps it
  but restores its meaning: `ignoreip` is scoped to named admin sources instead of whole tailnet/LAN
  CIDRs, so it actually throttles a compromised tailnet peer (ADR-0010).
- **n8n vs hermes cron:** v11 already re-scoped n8n to what cron cannot do (OAuth'd web integrations);
  v12 keeps that scoping and adds the license caveat (fair-code, not OSI).

### 4. Missing capabilities for ADHD/life automation (added in v12)

- **Document/life-admin ingest:** nothing in v11 handled the paper/PDF/receipt/admin-document stream that
  is a core ADHD executive-function tax. Paperless-ngx is the v12 anchor add (consume folder + mail rules
  \+ API; full `document_exporter` round-trip).
- **A daily brief:** v11 had the parts (Elaine, calendar, Todoist, alerts, Karakeep) but never the
  assembled artifact. v12 makes the **morning brief** the flagship autonomous data/knowledge workflow
  (Track L).
- **Finance visibility:** no budgeting capability existed; Actual Budget enters as the strict-class
  trial.
- **Surfacing, not just storing:** Hindsight stored memories, but nothing scheduled recall ("you said X
  three weeks ago, deadline tomorrow"). v12 adds scheduled recall/resurfacing jobs to Track L.
- **Capture friction:** the iPhone Shortcut → Karakeep path existed; v12 extends capture-anything (voice
  note → transcript → vault inbox) as an experiment.

### 5. Missing capabilities for the AI/devops platform (added in v12)

- **No CI at all:** v11 tested by checklist. v12 adds Forgejo + Forgejo Actions (GitHub mirror + CI on
  the NUC) so lint/validation/smoke run on every push, plus Renovate (dependency PRs, human-merged, per
  ADR-0006).
- **No agent-grounding corpus:** agents could not answer "what did we decide about X" from the repos.
  v12's knowledge track ingests homelab + dotfiles + worktrees into `homelab-knowledge` with
  canonical-path citation.
- **No LLM observability:** spend and traces were invisible. LiteLLM (budgets/keys) and Langfuse
  (tracing; hermes plugin exists) enter as experiments sized honestly (Langfuse v3 is a 5-service stack).
- **No private search backend for agents:** SearXNG added.

### 6. Missing or weak backup/restore/export stories (fixed in v12)

Strong in v11: Postgres, OpenBao, etcd, Longhorn, B2. Gaps now closed in the v12 coverage table: **hermes
state** (wrong path, no restore test), **Karakeep/Home Assistant PVC drills** (named restore tests
added), **Wazuh indexer** (moot, deferred), **KDC db2 store** (restored with Track I, including its
dump/restore drill), **the Pi itself** (now stateful: its quadlet units + Prometheus/Loki data get a
documented rebuild-vs-restore split), **Grafana dashboards** (provisioned-as-code, rebuildable),
**Forgejo** (repos are mirrors + file-level DB backup, avoiding the documented `forgejo dump` SQL-restore
bugs), **Paperless** (nightly `document_exporter` + originals dir canonical).

### 7. Missing or weak test/validation gates (fixed in v12)

v11 had strong per-service Done-when lines but no harness: nothing ran them repeatedly. v12 adds the
five-layer pyramid (below) with CI for static checks, Gatus for continuous smoke, a restore-drill
calendar, synthetic workflow probes for the agent paths, and graduation gates for experiments. The
clawmail payload contract, flagged three times in v11, becomes a named Track L gate (L1).

### 8. Keep / replace / add / defer / reject (summary; full matrix in the companion doc)

- **Keep:** k3s+etcd, Traefik, cert-manager, CNPG Postgres+pgvector, ESO, OpenBao, Ansible Vault,
  KeePassXC, Authelia (file-backend bootstrap → LLDAP backend), **LLDAP, Kerberos KDC (+optional Pi
  kpropd slave), SSSD, fail2ban (scoped ignoreip)** (all four restored by ADR-0010 as
  defense-in-depth/learning, Track I), nftables, sshd hardening + break-glass, LUKS, chrony (re-promoted
  to hard Kerberos prerequisite), Tailscale + subnet router + ACLs + Lock, Pi-hole + Unbound (+ NUC
  secondary), cloudflared + clawmail, the human mailbox provider (ADR-0012), hermes (Bob/Elaine/Sierra),
  Hindsight, Karakeep + Meilisearch, FreshRSS, n8n (scoped), Home Assistant, Atuin, Restic + B2 (+
  rest-server on Pi, promoted).
- **Replace:** Promtail → Alloy; v11's monitoring placement (NUC) → Pi 5. The S1 client trial is
  deferred.
- **Add:** Paperless-ngx, Forgejo + Actions runner, Renovate, SearXNG, Gatus, the Pi heartbeat-overdue
  consumer, guest VLAN segmentation (ADR-0011), UniFi Threat Management + unpoller + Trivy + Lynis (the
  ADR-0013 security coverage bundle), Infisical Secrets Management + Agent Proxy (A6), NetBird (F4),
  Dozzle (F5), Open Notebook (L6).
- **Experiment:** Actual Budget (strict), Immich (gated on the 4TB SSD), Langfuse, LiteLLM, Ollama (CPU,
  utility models), Vikunja, KeePassium (deferred), Mouse (deferred-experiment), AgentMail (scoped to
  agent-owned inboxes, ADR-0012).
- **Defer:** Wazuh (fleet gate), Headscale, Radicale/CalDAV, OpenAleph (own future NUC, unchanged), v8
  5-node HA scale-out (unchanged).
- **Reject:** Firefly III, Vaultwarden, Donetick, Habitica, Stirling-PDF (run ad-hoc, not standing), Open
  WebUI (interface sprawl; Discord/hermes is the interface), CrowdSec (carried rejection).
  (Kerberos/LLDAP/SSSD/fail2ban were rejected by the initial pass and restored by owner decision,
  ADR-0010.)

### 9. Dotfiles boundary (split-by-lifecycle; proposals only, nothing moved in this task)

| Item                                                                                                                 | Today                                                         | v12 proposal                                                                                                                                                   | Rationale                                                                               |
| -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| hermes server config + webhook route registry                                                                        | runtime-only `~/.hermes` on the Mac, "nobody's repo"          | **move to homelab** when hermes lands on the NUC; homelab owns the route registry + per-route secret templating via Ansible/OpenBao                            | shared service config is infra, not workstation config; closes the v11 L13 backlog item |
| OpenBao server artifacts (config, unit, policies, unseal)                                                            | nothing exists in dotfiles (verified)                         | **create in homelab from day one**; dotfiles keeps only client env rendering                                                                                   | PLAN-OPENBAO's own Phase-2 intent                                                       |
| Infisical + Agent Proxy (A6)                                                                                         | planned, not deployed by this addition                        | **homelab** owns deployment, identities, policies, networking and recovery; **dotfiles** owns laptop clients, non-secret harness configuration and uu upgrades | server and workstation lifecycles remain separate                                       |
| cloudflared tunnel definition + credentials                                                                          | brew installs the binary only                                 | **homelab** owns tunnel config/creds (ESO/Ansible)                                                                                                             | the ingress is core infra                                                               |
| Hindsight Postgres+pgvector                                                                                          | brew formulae present, workstation setup explicitly postponed | **NUC CNPG** is canonical; brew packages remain optional dev clients                                                                                           | closes dotfiles plan item P2 the way its author predicted                               |
| osquery fleet design (Linux packs, Ansible deploy, Pi consumer)                                                      | design docs in the worktree, Mac-only deployment              | **homelab** owns the fleet design and Linux deployment; the Mac pipeline stays chezmoi-owned until the named trigger (hermes relocation)                       | the worktree docs state this migration intent verbatim                                  |
| gha-watcher (GitHub workflow_run poller, planned)                                                                    | dotfiles plan defaults to Mac-local                           | **undecided**; revisit once hermes is on the NUC (an always-on poller fits the NUC, but the dotfiles plan already rejected a second ingress and chose polling) | respect the in-flight dotfiles refactor                                                 |
| Paseo CLI/daemon, nvim overhaul, atuin client, td CLI, KeePassXC templates, alerter/Hue UX, AI CLIs, Claude settings | dotfiles                                                      | **stay in dotfiles**                                                                                                                                           | per-user, per-machine workstation lifecycle                                             |

Superseded documents (historical record only, do not implement from): PLAN.md, PLAN-v2 through PLAN-v8
(v8 remains the scale-out reference), PLAN-v9, PLAN-v10, PLAN-URIEL-SERVICE-LAYOUT-v1,
remote-access-architecture.md (TorGuard sketch), technologies.md, the 2026-05-14 session summary.
PLAN-OPENBAO (Phase 1) remains live until the F1.4 migration completes. PLAN-v11 remains the
implementation spec for Wazuh (deferred), for the reinstated Cilium/Longhorn substrate (now day-one
work), and for everything v12 carries unchanged.

______________________________________________________________________

## End-state architecture

```
┌──────────── Home network (behind CGNAT), HOMELAB VLAN 192.168.1.0/24; guests on their own ─────────┐
│             isolated VLAN/SSID with NO route here (ADR-0011; UniFi gateway enforces)               │
│                                                                                                    │
│  lash (NUC, 64GB / 1→4TB NVMe), SERVICE + AI PLATFORM (accepted SPOF for apps, not for paging)     │
│   SINGLE-NODE k3s, v11 substrate: embedded etcd · Cilium (KPR+LB-IPAM+L2) · Longhorn (r1)          │
│   - Traefik · cert-manager (DNS-01) · ESO                                                          │
│   - CNPG Postgres + pgvector (single, Barman PITR → B2)                                            │
│   - OpenBao (single-node Raft, seal "static") · Authelia (file bootstrap → LLDAP backend)          │
│   - LLDAP (directory) · Kerberos KDC (db2; kpropd slave option on the Pi) · SSSD     [Track I]     │
│   - clawmail (email ingress app) · cloudflared (the ONE tunnel)                                    │
│   - Karakeep + Meilisearch · FreshRSS · n8n (scoped) · Home Assistant · Atuin                      │
│   - Paperless-ngx (+ its Redis) · SearXNG · Forgejo + Actions runner (+ Renovate job)              │
│   - Hindsight (memory service :8888, local embeddings, banks per agent + shared knowledge banks)   │
│   Native systemd (NOT k3s):                                                                        │
│   - hermes-gateway-bob (general/coding, Codex OAuth → fallback_providers)                          │
│   - hermes-gateway-elaine (paranet: clawmail webhook + iMessage)                                   │
│   - hermes-gateway-sierra (hard-isolated rootless Podman, v11 §5.13)                               │
│   - osquery (Linux port of the two-tier page/log design) · auditd (trimmed) · Alloy → Pi Loki      │
│                                                                                                    │
│  the Pi (Raspberry Pi 5, 16GB, NVMe), RESILIENCE/EDGE APPLIANCE (no k3s; systemd + Podman quadlets)│
│   - Pi-hole + Unbound (primary DNS) · chrony NTP master · Tailscale subnet router                  │
│   - Prometheus · Loki · Grafana · Alertmanager   (the observability stack, moved here)             │
│   - ntfy (push) · Gatus (synthetic smoke checks) · Alloy (local logs)                              │
│   - restic rest-server --append-only (second repo, NVMe) · Healthchecks heartbeat                  │
│   - heartbeat-overdue consumer (pages when a host's check-in goes silent)                          │
│   Placement test: everything needed to notice/page/diagnose a lash outage lives here.              │
└────────────────────────────────────────────────────────────────────────────────────────────────────┘
        ▲                      ▲                       ▲                        ▲
        │ mlx-audio TTS        │ BlueBubbles           │ remote MCP (Obsidian/  │ Tailscale (ACLs+Lock);
        │ (OpenAI-compat)      │ webhook → Elaine      │ filesystem) over       │ remote access via the
        ▼                      │ :8645                 │ tailnet, NUC ← Mac     │ Pi's subnet route
┌─────────── dresden (M1 MacBook), security-monitored endpoint + resource host ───────────┐
│  - BlueBubbles Server · mlx-audio Kokoro TTS · Mac-resource MCP servers                  │
│  - osquery two-tier pipeline (as-built, chezmoi-owned until hermes relocates)            │
│  - Tailscale (Tailnet Lock signing node)                                                 │
└──────────────────────────────────────────────────────────────────────────────────────────┘
   mister (iPhone): Karakeep, HA Companion, ntfy, Shortcuts, Strongbox (kdbx), Tailscale

Cloudflare: DNS + DNS-01 ACME. The clawmail project owns the routing provider (S5 trial) →
cloudflared tunnel → clawmail → Elaine's hermes webhook route. The ONE application ingress,
private-to-Stephen (ADR-0002). F4 must separately resolve NetBird control/relay hosting.
```

RAM ledgers (requests-level, measured at deploy and enforced by the Phase-gate "Σ requests + floor ≤
allocatable"):

| NUC (64GB)                                                   | est.      |     | Pi 5 (16GB)                     | est.             |
| ------------------------------------------------------------ | --------- | --- | ------------------------------- | ---------------- |
| k3s + system floor                                           | ~2.5GB    |     | Pi-hole + Unbound               | ~0.4GB           |
| CNPG Postgres (shared_buffers 4GB)                           | ~6GB      |     | Prometheus                      | ~1.5GB           |
| Hindsight (full image, local models)                         | ~3GB      |     | Loki                            | ~1.0GB           |
| hermes ×3 + clawmail                                         | ~2GB      |     | Grafana                         | ~0.5GB           |
| Karakeep + Meilisearch + Chrome                              | ~2.5GB    |     | Alertmanager + ntfy + Gatus     | ~0.5GB           |
| Paperless + Redis                                            | ~1.5GB    |     | Alloy + rest-server + consumers | ~0.5GB           |
| Forgejo + runner                                             | ~2GB      |     | chrony + tailscaled + system    | ~0.6GB           |
| HA + n8n + FreshRSS + Atuin                                  | ~3GB      |     | **Pi total**                    | **~5GB of 16GB** |
| Traefik/cert-manager/ESO/OpenBao/Authelia/SearXNG            | ~2.5GB    |     | (target ceiling per ADR-0001)   | \<8GB            |
| **NUC steady-state total**                                   | **~25GB** |     |                                 |                  |
| Headroom for experiments (Immich ~8, Langfuse ~6, Ollama ~6) | ~39GB     |     |                                 |                  |

The September additions A6, F4, F5 and L6 are not included in these June totals. Measure their full
resource budgets and recalculate headroom before choosing placement.

Uncertain: per-service figures are estimates from official requirements where published (Immich 6GB
minimum, Langfuse 16GB-class compose guidance, Wazuh 8GB floor informing its deferral) and from training
elsewhere; the deploy gate measures real values.

______________________________________________________________________

## Operating model

- **Autonomy (ADR-0006):** dev agents propose, humans merge; non-code automations run autonomously only
  when observable, reversible, gated, and replayable. First autonomous category: data/knowledge
  automation.
- **Knowledge (ADR-0004):** canonical files, derived stores rebuildable by named jobs; agents cite
  canonical paths; first corpus is the two repos + worktrees.
- **AI compute (ADR-0003):** cloud frontier for reasoning/coding; local for embeddings, rerank, STT/TTS,
  OCR, small classifiers; no GPU pretensions.
- **Notifications (ADR-0014):** Discord is the single pane, hermes-mediated, with a fixed small channel
  set and severity tiering (page vs digest, on the osquery v2 template). Delivery layers: hermes →
  Discord; Pi-Alertmanager → Discord webhook (NUC down); ntfy (Discord down); Healthchecks (everything
  down). New services must wire in as an adoption gate; their native notifications are disabled where
  possible.
- **Attention budget:** every matrix row carries `attention: none | quarterly | monthly | weekly`.
  Weekly-care services must name the life-or-platform value that pays for it. v12's steady-state target:
  zero weekly-care services outside the agent layer itself.

______________________________________________________________________

## Service portfolio rationale (summary)

The full matrix with all fields is in `PLAN-v12-service-matrix.md`. The shape:

- **The agent layer is the product**; everything else exists to feed it (knowledge, email, documents,
  telemetry) or keep it trustworthy (backups, tests, security floor).
- **Life-automation spine:** clawmail→Elaine (comms triage), Paperless (documents), Karakeep+FreshRSS
  (reading), Hindsight (memory + resurfacing), HA (home events), ntfy/Discord (delivery), the morning
  brief (assembly).
- **Platform spine:** Forgejo+Actions+Renovate (CI and human-reviewed agent PRs), the knowledge corpus
  (grounded answers), SearXNG (search), Gatus+Prometheus (truth about the system).
- **Replacement trials are isolated:** strict-class (Actual Budget) and standard-class (KeePassium, later
  Immich/Vikunja) run on the experiment track and cannot block the spines.
- **Security floor:** guest VLAN segmentation (ADR-0011: guests are internet-only, client-isolated, no
  route to the homelab VLAN) + nftables (host grants by named IP, not /24) + sshd+break-glass + LUKS +
  Tailscale ACLs/Lock + Authelia + OpenBao + auditd→Loki + osquery two-tier + fail2ban (scoped ignoreip).
  Each layer names the attack it stops; the named live threat the LAN layers now share is an untrusted
  guest device inside the house.
- **Identity depth (Track I, ADR-0010):** LLDAP + Kerberos + SSSD as the deliberate enterprise-IAM layer,
  sequenced after life-automation first value, with full backup/test parity. Classified honestly as
  skill-building breadth plus operational SSO, not as a new defense layer.

______________________________________________________________________

## Roadmap: parallel tracks with gates

Tracks run concurrently; gates are checklists, not dates. Useful life improvement must not wait for a
perfect platform: Track L starts the moment F1 passes, and F1 now carries the full v11 substrate scope
(owner decision, question 1), making it the long pole of Track 0; Track L still starts the moment F1
passes.

### Track 0, Foundation (security floor, backups, testing harness)

- **F0 host baseline:** Ubuntu/Debian on NUC, Pi OS/Debian on Pi 5 (NVMe boot). **Network segmentation
  first (ADR-0011 + its casting amendment): three segments.** Guest SSID → isolated VLAN (client
  isolation on, internet-only, optional single flow to the Pi-hole :53 as the ad-blocking perk); a
  **Media/IoT VLAN** holding the TV (and future cast/smart-home devices) with UniFi mDNS reflection
  guest↔media plus a narrow guest→TV cast-port allowance (AirPlay confirmed 2026-06-11: pin its
  documented port set at setup) so movie-night casting works; homelab devices on the homelab VLAN/SSID
  whose passphrase guests never receive. Asymmetry: homelab→media allowed (Stephen casts, HA integrates
  the TV), media→homelab denied, guest→homelab denied. The intended VLAN/SSID/firewall layout documented
  in the repo. Then nftables (three trust planes; **host grants by named IP, not the /24**; Cilium port
  set per v11 0.8.1, ADR-0008 reversed), sshd hardening + local `sshusers` + break-glass (v11 0.8.2
  carried), LUKS (threat-model note carried), chrony (Pi master), Tailscale + ACLs + Lock (subnet router
  advertises the homelab VLAN only), unattended-upgrades. Pre-commit suite in the repo (yamllint,
  ansible-lint, shellcheck, markdownlint, gitleaks).
- **F1 platform ready (gates Track L and A):** k3s pinned with the v11 substrate (embedded etcd, Cilium
  KPR + LB-IPAM + L2 with the policy-surface allow-set and policyAuditMode rollout, Longhorn replica-1)
  plus the Cilium/Longhorn drills restored to the testing layer; Traefik + cert-manager (Ansible-Vault
  interim Cloudflare token); CNPG single Postgres (data on Longhorn per the v11 decision) + Barman to B2
  **with the scratch-restore demo passing**; OpenBao single-node Raft + seal-static + ESO sync demo;
  **F1.4: the dresden→lash OpenBao migration** (kv re-load per PLAN-OPENBAO, AppRole→k8s-auth swap,
  retire the Mac server); Authelia (file backend) in front of the first UI; Restic nightly → B2 (Object
  Lock, Governance mode) + **rest-server append-only on the Pi**; Healthchecks wired. Done when: every F1
  component has its smoke check in Gatus and its row in the backup coverage table.
- **F2 DR proven (gates strict-class trials):** quarterly-style full drill executed once: etcd snapshot
  restore to scratch, Postgres PITR to scratch, OpenBao snapshot restore + unseal, one PVC restore from
  B2 and one from the Pi repo, Pi rebuild-from-Ansible check. Done when: the drill runbook has timestamps
  and a pass.
- **F3 observability + security telemetry on the Pi:** Prometheus/Loki/Grafana/Alertmanager/ntfy/Gatus as
  quadlets; Alloy on both hosts (Promtail never deployed); **the ADR-0014 notification chain wired**
  (Alertmanager → alerthook-router/hermes → Discord primary; Alertmanager → Discord webhook secondary;
  ntfy tertiary); heartbeat-overdue consumer live; **the ADR-0013 bundle**: UniFi Threat Management
  enabled on the gateway, unpoller shipping threat events into Prometheus/Loki, the Grafana Security
  folder provisioned, Lynis monthly crons + Trivy host-scan digests scheduled. Done when: with the NUC
  powered off, Grafana still serves and the outage page arrives **in Discord** via the Pi's Alertmanager
  webhook (ntfy proven separately by a Discord-path-down drill); a gateway threat event appears in Loki
  and pages per its severity tier; Healthchecks fires the dead-man.

#### F4, NetBird remote access

Owner addition, 2026-09-12: plan and deploy self-hosted [NetBird](https://github.com/netbirdio/netbird).
[Task](https://app.todoist.com/app/task/6hVpfWghCjQ66GG3).

- [ ] Resolve server placement against the home connection's address and inbound-access limits. The
  [upstream self-hosting guide](https://docs.netbird.io/selfhosted/selfhosted-quickstart) requires a
  publicly reachable server and domain; record hosting cost and recovery before selecting a host.
- [ ] Map Tailscale's existing access policies, device enrollment/revocation, private name resolution,
  subnet routes and recovery requirements to NetBird. Keep Tailscale operational until a reviewed cutover
  passes; Headscale remains deferred. A6 uses Tailscale until this migration changes it.
- [ ] Configure protected administration, minimum device/service access and private Infisical access.
  Verify a roaming Mac, an iPhone on cellular, denied access, lost-device revocation and outage recovery.
  Back up server state/configuration and prove restoration. Homelab owns servers and policies; dotfiles
  owns laptop clients and updates. Adding NetBird does not replace Infisical's credential broker.

#### F5, Dozzle live container logs

Owner addition, 2026-09-12: deploy [Dozzle](https://github.com/amir20/dozzle) for quick inspection of
live container logs after F1. [Task](https://app.todoist.com/app/task/6hVpfWmPgm7qQHMV).

- [ ] Use [Kubernetes mode](https://dozzle.dev/guide/k8s) for k3s with the required metrics service and a
  service account limited to the intended namespaces. Verify Pi coverage through the supported
  [Podman integration](https://dozzle.dev/guide/podman). Keep Alloy/Loki responsible for retained logs
  and alerting, including native system services.
- [ ] Require private authenticated access and minimum log-reading permissions. Keep terminal access and
  container actions disabled. Check representative logs and denial of unauthenticated access; measure
  resource use and verify rebuilding the viewer from managed configuration. Authentication defaults to
  none; configure it explicitly using the [upstream guidance](https://dozzle.dev/guide/authentication).

### Track A, AI/devops platform

- **A1 Forgejo:** deploy + mirror homelab/dotfiles from GitHub; SSH over tailnet only; backup = mirrored
  repos + file-level SQLite/data backup (avoid `forgejo dump` SQL restore).
- **A2 CI:** Forgejo Actions runner; pipeline = pre-commit suite + kubeconform on `k8s/` +
  `ansible-playbook --syntax-check` + docs link check + **Trivy image/IaC scanning (fail on critical
  CVEs, ADR-0013)**. Branch protection on `main` (also enforces ADR-0006: no agent self-merge).
- **A3 Renovate:** scheduled job against Forgejo; PRs only; human merges.
- **A4 knowledge corpus:** ingest homelab + dotfiles + worktrees into Hindsight `homelab-knowledge`
  (document_id = repo-relative path, re-ingest on push via Forgejo webhook → hermes route); graduation:
  Bob answers "why did we defer Wazuh" with ADR-0009 cited by path.
- **A5 experiments:** Langfuse, LiteLLM, Ollama per backlog.

#### A6, self-hosted Infisical for agent credentials

Approved for planning on 2026-09-12. Deploy [Infisical](https://github.com/Infisical/infisical) Secrets
Management and Agent Proxy after the required F1 platform and F2 restore checks. Track in
[Todoist](https://app.todoist.com/app/task/6hVpX4M8hmV4Gmr3). This addition authorizes planning only.

- [ ] Inventory the credentials needed by Claude Code, Codex and Hermes, including nicodemus, on each
  development laptop and homelab runtime. Assign one authoritative store per credential. Reconcile
  OpenBao's planned agent consumers and F1.4 migration before expanding either store; record which
  infrastructure consumers remain in OpenBao. Preserve rollback until replacement access is proven.
- [ ] Use the supported self-hosted deployment on the NUC, with a pinned release, measured resource
  budget, PostgreSQL and persistent Redis with `noeviction`, private HTTPS and existing monitoring.
  Configure the service URL, protected bootstrap keys and email delivery for account recovery. Verify the
  selected self-hosted edition supports the required proxy permissions, audit records, authentication and
  rotation features. Confirm self-hosted entitlements and cost before committing to a license; a listed
  Agent Proxy feature alone does not establish the required isolation controls.
- [ ] Reuse the existing Tailscale network and Pi subnet router. Give all enrolled development laptops
  the same private service hostname and restrict access by device and role. The iPhone may reach the
  dashboard for occasional administration; everyday mobile password access remains in Strongbox. Verify
  name resolution and certificate trust on outside Wi-Fi and cellular. Keep the service off the public
  internet; a home connection outage remains an outage.
- [ ] Configure each roaming laptop's Infisical command-line client with the self-hosted
  `INFISICAL_DOMAIN`, private `INFISICAL_AGENT_PROXY_ADDRESS` and its scoped machine authentication.
  Launch agents through `infisical secrets agent-proxy connect -- <agent command>`. Over Tailscale, the
  home proxy authenticates the agent and adds credentials to approved service requests; the laptop
  receives responses without the brokered secret values. This does not require opening the dashboard for
  each use. Verify each harness and its tools respect the proxy and certificate trust.
- [ ] Separate human administration from agent identities. Require multi-factor authentication for human
  access, minimum project/environment permissions for agents, short-lived access where supported, and
  independent revocation for a lost laptop or compromised harness. Protect bootstrap credentials outside
  agent-readable files; define supported rotation for each downstream credential.
- [ ] Choose a separate proxy host from agent runtimes, following the standalone deployment model.
  Resolve placement before deployment, including for agents intended to run on the NUC. Configure Agent
  Proxy for approved services. Grant agent identities permission to use the proxy without permission to
  read secret values. Keep the proxy identity and its credentials outside the agent's execution boundary,
  including for agents hosted on the NUC. Enforce destination restrictions and prevent agent shell
  commands, writable launch scripts or administrator access from bypassing that boundary. Runtime
  environment injection alone does not meet this requirement.
- [ ] Keep personal logins in the canonical KeePass database used by KeePassXC and Strongbox. Test iPhone
  AutoFill and access to a locally available database while offline. Register only credentials selected
  for agent use in Infisical, preferably dedicated agent accounts or restricted access tokens. If an
  agent needs an existing personal login, keep that selected password in both stores and record who owns
  rotation and how both copies are updated. Strongbox does not gain access to Infisical by this
  arrangement. The older S1 KeePassium trial is deferred and independent of Infisical. Do not create
  automatic bidirectional vault synchronization.
- [ ] Define disconnected behavior: protected agent operations stop clearly when their required broker
  cannot be reached; ordinary local development remains usable. Document existing-session and
  token-expiry behavior. Do not silently export credentials to laptops as an offline workaround.
- [ ] Back up PostgreSQL, Redis persistence, deployment configuration and the original `ENCRYPTION_KEY`
  through the existing backup system. Keep bootstrap recovery available without Infisical. Test restoring
  readable secrets and working proxy policies into an isolated instance. Route service failures and
  relevant audit events through the existing monitoring/Discord path without secret values.
- [ ] Verify with dummy credentials first: approved calls succeed from each harness, direct secret reads
  and unapproved destinations fail, revocation blocks new access, and logs/transcripts contain no
  credential values. Test a roaming Mac, an iPhone on cellular, a disconnected laptop and a home server
  outage. Run the strict secrets cutover checks before moving real credentials.
- [ ] Coordinate client installation, self-hosted endpoint settings, trust configuration and uu upgrades
  with dotfiles. Review local file-rendering needs separately: the proxy handles outbound requests, so it
  does not itself authorize or secure `chezmoi apply`. Continue the
  [existing credential-access review](https://app.todoist.com/app/task/6hPCF99XjRP87GmM); the
  operator-only apply rule remains until its replacement is approved and verified.

Implementation references: [self-hosting](https://infisical.com/docs/self-hosting/overview),
[service requirements](https://infisical.com/docs/self-hosting/configuration/requirements),
[feature tiers](https://infisical.com/pricing) and
[self-hosted licensing](https://infisical.com/docs/self-hosting/ee),
[standalone Agent Proxy](https://infisical.com/docs/documentation/platform/agent-proxy/standalone-agent-proxy),
[Tailscale subnet routers](https://tailscale.com/docs/features/subnet-routers).

### Track L, ADHD/life + knowledge automation

- **L1 comms spine (first life value):** hermes gateways on the NUC (profiles created fresh; no OpenClaw
  migration), Hindsight up, clawmail + tunnel cutover, **the clawmail→Elaine payload contract pinned and
  committed** (the thrice-flagged v11 gap), Discord triage live, BlueBubbles → Elaine. **Email scope
  boundary (2026-06-11): homelab deploys clawmail AND the cloudflared tunnel (the stable public ingress
  endpoint terminating at clawmail), and consumes the payload contract; clawmail is sender-agnostic, so
  the internet mechanics (MX, the routing provider, mailbox forwarding rules, S5 staging) are the
  clawmail project's work, swappable behind the tunnel URL without touching either deployment.** L1's
  external dependency is therefore: the clawmail project has its Stage-1 routing live and the **payload
  contract pinned and published**; homelab commits that pin and builds the Elaine synthetic against it.
  The architecture itself stays recorded in ADR-0012 (two planes; mailbox direction Proton-gated-on-S6;
  an agent-plane outage degrades to reading mail in the mailbox app). AgentMail is scoped to agent-owned
  inboxes only (and its leaked key rotated).
- **L2 morning brief (first autonomous workflow):** hermes cron assembles calendar + Todoist + Elaine's
  overnight triage + alerts + FreshRSS/Karakeep picks into one Markdown brief, delivered via Discord/ntfy
  and archived to the vault (canonical). Autonomous under ADR-0006 (observable, reversible, gated).
- **L3 documents:** Paperless-ngx (pin 2.20.x until v3 stabilizes); consume folder + mail-rule ingest
  from clawmail/Elaine ("file this receipt"); nightly `document_exporter` to canonical storage; agent
  access via API for "find my lease" queries.
- **L4 resurfacing:** scheduled Hindsight recall jobs (deadlines, commitments, "you wanted to revisit");
  weekly review digest.
- **L5 capture:**
  [vpp (Voice Processing Pipeline)](PLAN-v12-experiments-backlog.md#l-r5-vpp-voice-processing-pipeline),
  a planned Rust tool for Voice Memos ingestion, redundant transcription, related notes and meeting
  briefs. Bob can consume its outputs once built; calendar and Todoist inputs remain optional. Storage is
  configurable, including an Obsidian vault. Feature decisions and open questions live in L-R5.

#### L6, Open Notebook research workspace

Owner addition, 2026-09-12: deploy [Open Notebook](https://github.com/lfnovo/open-notebook) for research
notebooks, source-based questions and useful notes after F1/F2.
[Task](https://app.todoist.com/app/task/6hVpfWrX8W4jrQcV).

- [ ] Plan its application, SurrealDB and persistent files using a pinned supported deployment. Protect
  both the interface and application programming interface with private authenticated access; replace
  example credentials and keep the database internal. Measure its resource and care costs.
- [ ] Select approved model providers and scoped credentials; record what content leaves the homelab when
  a hosted model processes it. Keep original documents and exported durable notes in their canonical
  locations, including Obsidian; define the boundary with Hindsight's agent memory.
- [ ] Define an optional supported handoff from vpp (Voice Processing Pipeline), the planned Rust tool.
  Open Notebook must not create a second automatic Voice Memos capture/transcription workflow.
- [ ] Verify a representative import, an answer checked against its source, and a usable note export.
  Back up SurrealDB, uploaded/generated files and the original application encryption key; restore a
  notebook and its working provider configuration in isolation before relying on the service.

### Track S, subscription replacement trials (all per ADR-0007)

- **S1 KeePassium:** deferred under the September decision to retain KeePassXC/Strongbox. The earlier
  30-day client trial remains a proposal to revisit only with explicit approval.
- **S2 Actual Budget** (strict class): deploy, import YNAB data, 60-to-90-day dual-entry, SimpleFIN
  optional ($1.50/mo), go/no-go note before any cancellation.
- **S3 later candidates** (each gated on F2 + track capacity): Immich (also gated on the 4TB SSD),
  Vikunja, Radicale. Readwise replacement (Karakeep/FreshRSS loop) carries over from v11 and completes in
  Track L.

### Track H, Home Assistant integration

- **H1:** HA on k3s + CNPG recorder (v11 design carried); entities exposed to Bob via the hermes HA
  toolset (read + notify first).
- **H2:** two or three cautious automations max (observable, reversible: lights, reminders,
  presence-aware nudges); no locks/security actuation; events feed the morning brief.

### Track I, identity depth (defense-in-depth + devsecops learning; ADR-0010)

Starts only after L1 ships (may never block Tracks L/A). fail2ban is not gated here; it returns with the
F0 floor (scoped `ignoreip`).

- **I1 LLDAP:** single instance over CNPG (v11 3.1 corrected design: stateless, shared `LLDAP_KEY_SEED`);
  seed users/groups; **Authelia upgrades from file backend to LLDAP backend** (the file backend remains
  the tested de-escalation path).
- **I2 Kerberos KDC:** master on the NUC, own db2 store (never LLDAP-backed), realm `WEBDAVIS.IO`,
  host/user principals; chrony re-promoted to hard prerequisite with a skew assertion in the NTP smoke
  check; **nightly `kdb5_util dump` → canonical storage + Restic** (the backup row v11 never had).
- **I3 SSSD:** Linux hosts (Kerberos auth + LLDAP identity, cached); `dresden` via `dsconfigldap` +
  native Heimdal. Gate carried from v11: **break-glass local login proven with SSSD stopped** before
  SSSD-gated `AllowGroups` tightening.
- **I4 (optional) kpropd slave on the Pi 5:** existing-principal auth survives NUC maintenance; kprop
  schedule + stash distribution runbook.
- **Done when:** `kinit` issues a ticket; `ssh` via GSSAPI works host-to-host; `id` resolves LLDAP
  groups; Authelia authenticates against LLDAP; the KDC dump restore drill passes into a scratch realm;
  the break-glass gate passes; the learning-outcome list in ADR-0010 has evidence (runbooks written from
  doing, not copying).

______________________________________________________________________

## Testing strategy (the five-layer pyramid)

1. **Static (every push, CI):** pre-commit (yamllint, ansible-lint, shellcheck, markdownlint, gitleaks),
   kubeconform + kustomize build on `k8s/`, `ansible-playbook --syntax-check` and `--check` on a
   schedule, version-pin lints. Policy checks (conftest) are evaluated with the reinstated Cilium work.
1. **Deployment smoke (continuous, Gatus on the Pi + CI job):** per-service HTTP/auth checks behind
   Authelia, DNS answers from both resolvers, certificate expiry windows, `pg_isready`, OpenBao seal
   status, hermes `gateway status` + `webhook test` + `cron tick`, tunnel liveness (Blackbox on the
   clawmail hostname), storage free-space; a **segmentation probe** (from the guest segment: the homelab
   subnet is unreachable except the explicitly enabled Pi-hole port 53 allowance, if selected; the TV is
   discoverable and castable, and nothing else on the media VLAN answers; from the media VLAN: the
   homelab subnet is unreachable; run after any UniFi change and quarterly); **notification-chain
   drills** (test alert lands in Discord via hermes; NUC-down → Pi-Alertmanager Discord webhook;
   Discord-path-down → ntfy); **security-coverage freshness** (unpoller scrape, weekly Trivy digest,
   monthly Lynis report); once Track I lands: `kinit` ticket smoke, SSSD `id` lookup,
   chrony-skew-within-Kerberos-tolerance assertion, fail2ban jail-active + scoped-`ignoreip` assertion.
1. **Restore (calendar):** monthly tier-1 (Postgres PITR to scratch namespace; OpenBao snapshot restore;
   one PVC/file restore alternating B2 ↔ Pi repo; Paperless export re-import spot check). Quarterly
   tier-2 (etcd `--cluster-reset` to scratch; Pi rebuild from Ansible; hermes state restore incl.
   `auth.json` OAuth survival). Every drill writes a timestamped log to the repo.
1. **Workflow synthetics (scheduled):** end-to-end email (test message → the clawmail project's routing
   layer → clawmail → Elaine → Discord, asserting the pinned payload contract), morning-brief generation
   \+ delivery + vault archive, knowledge canary (edit a canary doc, re-ingest, Bob must cite the new
   content by path), HA event → notification, finance-import dry run during S2, backup-success
   Healthchecks pings distinct from liveness.
1. **Gates:** experiment → core requires the ADR-0007 seven gates plus: a matrix row updated with
   measured RAM/attention class, a backup-coverage row with a passed restore, a Gatus check, and a
   runbook (deploy, upgrade, restore, kill-switch). Core → retired requires a final export to canonical
   storage.

______________________________________________________________________

## Migration and cutover gates

ADR-0007 governs all replacements. Summary of classes and the planned trials:

| Trial                             | Class                       | Parallel run             | Hard requirements before cutover                                                                                             | Rollback                                                               |
| --------------------------------- | --------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Strongbox → KeePassium (deferred) | standard                    | 30 days if reopened      | kdbx opens/edits cleanly on iPhone+Mac; AutoFill verified; free-tier limits acceptable or one-time Pro                       | re-open Strongbox (kdbx unchanged)                                     |
| YNAB → Actual Budget              | **strict**                  | 60 to 90 days dual-entry | YNAB import verified; zip export re-import demonstrated; restore from B2 demonstrated; reconciliation matches across the run | re-import final export to YNAB; resubscribe; documented before cutover |
| Readwise → Karakeep/FreshRSS loop | standard                    | carried from v11         | highlights/export archive landed in canonical storage                                                                        | resubscribe                                                            |
| Google Photos → Immich            | standard (privacy-weighted) | 60 days                  | gated on 4TB SSD; mobile background backup proven; DB dump + originals restore demonstrated                                  | originals are canonical files; takeout re-upload                       |
| Todoist → Vikunja                 | standard                    | not scheduled            | only if CalDAV/iOS matures; td-CLI workflow parity                                                                           | Todoist importer exists both ways                                      |

Identity migration (v11 → v12): no data moves; LLDAP/Kerberos were never deployed and now arrive fresh
via Track I (ADR-0010). The planned OpenBao migration is **dresden → lash (F1.4)**, subject to the A6
ownership review and fresh runtime inventory: stand up lash OpenBao, `bao kv get/put` re-load of the
small secret set, repoint `BAO_ADDR`, swap AppRole → k8s-auth for in-cluster consumers, keep the Mac
server until the lash instance passes its restore drill, then retire it.

______________________________________________________________________

## Backup/restore coverage (per stateful service)

Canonical-vs-derived per ADR-0004; mechanisms; every row has a named restore test in the layer-3
calendar.

| Service                                                                                                                                               | Canonical data                                                                 | Mechanism                                                                                                                                                        | Restore test                                                                |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| NetBird (F4)                                                                                                                                          | control-service state, identities, policy and protected configuration          | supported state backup plus configuration through existing backup storage                                                                                        | restore enrollment/policies and prove remote access with rollback available |
| Dozzle (F5)                                                                                                                                           | viewer configuration; retained logs remain with their existing owners          | managed configuration; no separate log archive                                                                                                                   | rebuild authenticated viewer and inspect representative logs                |
| Open Notebook (L6)                                                                                                                                    | notebook database, files and provider encryption key                           | SurrealDB backup, persistent files and protected key recovery                                                                                                    | restore notebook, sources and usable provider configuration                 |
| Postgres (all app DBs incl. Hindsight banks)                                                                                                          | app data                                                                       | Barman PITR → B2; nightly base backup                                                                                                                            | monthly PITR to scratch                                                     |
| OpenBao                                                                                                                                               | secrets                                                                        | hourly Raft snapshot → PVC → Restic; direct-to-B2 push for 1h RPO                                                                                                | monthly snapshot restore + unseal                                           |
| Infisical (A6)                                                                                                                                        | agent secrets, identity/policy state and required encryption material          | PostgreSQL and Redis backups plus configuration and original encryption-key recovery through existing backup storage; bootstrap copy available without Infisical | isolated restore proves readable secrets, proxy access and denied raw reads |
| etcd (k3s)                                                                                                                                            | cluster objects only (not a system backup)                                     | scheduled snapshots → B2                                                                                                                                         | quarterly `--cluster-reset` to scratch                                      |
| hermes state (`~stephen/.hermes`, per profile: config, `auth.json`, `state.db`, `jobs.json`, workspaces; **path fixed from v11's `/var/lib/hermes`**) | agent identity + history                                                       | Restic nightly (NUC) + Pi repo                                                                                                                                   | quarterly restore incl. OAuth-token survival check                          |
| Human mailbox (SaaS, ADR-0012)                                                                                                                        | the canonical mail store                                                       | periodic provider export (IMAP pull/Takeout) → canonical storage                                                                                                 | export-freshness check; agent-plane-down delivery synthetic                 |
| clawmail                                                                                                                                              | processing archive + config (system of record is the human mailbox, ADR-0012)  | Restic                                                                                                                                                           | monthly file restore spot check                                             |
| Paperless-ngx                                                                                                                                         | originals dir (canonical) + DB                                                 | originals via Restic; nightly `document_exporter`; DB via Barman                                                                                                 | monthly exporter re-import to scratch                                       |
| Karakeep                                                                                                                                              | saved content + DB                                                             | DB via Barman; assets PVC via Restic                                                                                                                             | quarterly PVC restore                                                       |
| Meilisearch                                                                                                                                           | none (derived)                                                                 | rebuild job from Karakeep                                                                                                                                        | rebuild drill, not restore                                                  |
| Home Assistant                                                                                                                                        | `/config` PVC                                                                  | Restic                                                                                                                                                           | quarterly PVC restore                                                       |
| Forgejo                                                                                                                                               | git repos (mirrors of GitHub = double-covered) + SQLite/data dir               | file-level Restic of data dir; repos re-mirrorable                                                                                                               | quarterly data-dir restore; avoid `forgejo dump` SQL path                   |
| Actual Budget                                                                                                                                         | budget file (SQLite)                                                           | app zip export nightly + Restic                                                                                                                                  | part of S2 gates                                                            |
| Atuin                                                                                                                                                 | history DB                                                                     | Barman (shares Postgres)                                                                                                                                         | covered by PITR drill                                                       |
| FreshRSS / n8n / SearXNG / Authelia                                                                                                                   | small DB/config                                                                | Barman + config-in-repo                                                                                                                                          | covered by PITR drill + rebuild                                             |
| LLDAP (Track I)                                                                                                                                       | user directory                                                                 | rides Barman (CNPG-backed)                                                                                                                                       | covered by PITR drill; Authelia file backend is the outage fallback         |
| Kerberos KDC db2 store (Track I)                                                                                                                      | realm principals + stash                                                       | nightly `kdb5_util dump` → canonical + Restic; stash in KeePassXC                                                                                                | quarterly restore into a scratch realm (the row v11 lacked)                 |
| Hindsight banks                                                                                                                                       | derived (with the ADR-0004 nuance: durable facts also land in canonical files) | Postgres PITR + re-ingest jobs                                                                                                                                   | knowledge canary + rebuild drill                                            |
| Prometheus/Loki (Pi)                                                                                                                                  | derived telemetry                                                              | best-effort local snapshots; quadlet units in repo                                                                                                               | Pi rebuild-from-Ansible drill                                               |
| Grafana (Pi)                                                                                                                                          | none (dashboards provisioned as code)                                          | repo                                                                                                                                                             | rebuild                                                                     |
| kdbx (KeePassXC/Strongbox)                                                                                                                            | the canonical secret store                                                     | existing multi-location sync + Restic copy                                                                                                                       | open-from-backup check                                                      |
| Obsidian vault                                                                                                                                        | canonical knowledge                                                            | git (Obsidian Git) + Restic                                                                                                                                      | git is the restore                                                          |

______________________________________________________________________

## Questions for Stephen, now answered (locked 2026-06-11)

1. **Substrate diet (ADR-0008)?** **Answered (2026-06-11): reinstate the v11 substrate.** Cilium (KPR +
   LB-IPAM + L2) and Longhorn return as day-one Track 0 work with the corrected v11 designs as spec;
   ADR-0008 is reversed and its diet becomes the documented de-escalation path.
1. **Observability single-instance on the Pi?** **Answered (2026-06-11): yes, Pi-only.** Healthchecks.io
   stays the external dead-man for the Pi; the second Pi 5 becomes a pre-imaged cold standby configured
   **after the homelab is stable** (nice-to-have shelf row, not core-track work). No NUC Alertmanager
   replica.
1. **clawmail vs plain IMAP for Elaine (ADR-0002)?** **Answered (2026-06-11): keep clawmail.** IMAP
   polling stays the documented, rehearsed fallback; if S6 (Proton Bridge) graduates, the Bridge-IDLE
   local-push wiring can later delete the tunnel without losing clawmail.
1. **Finance trial (S2)?** **Answered (2026-06-11): yes to both.** The 60-to-90-day dual-entry run is
   approved (still gated on F2: DR proven) and SimpleFIN ($1.50/mo) is accepted for bank sync.
1. **Strongbox license?** The 2026-06-11 answer proposed a 30-day KeePassium trial. **Superseded by the
   September instruction to keep KeePassXC/Strongbox:** S1 is deferred; no trial start or cancellation is
   recorded by this publication.
1. **Todoist?** **Answered (2026-06-11): keep paying.** The td-CLI/agent investment stands; Vikunja stays
   shelved with its 3.x-maturity trigger.
1. **Immich timing?** **Answered (2026-06-11): the 4TB NVMe is not happening this cycle.** Immich stays
   shelved with the SSD as its named trigger; Google Photos keeps the job in the interim.
1. **The second Pi 5?** **Answered via question 2 (2026-06-11): cold-standby seed**, imaged
   post-stability; it also remains the natural second k3s node if scale-out ever fires (compatible roles:
   an unpromoted standby can be repurposed).
1. **AgentMail key in `docs/sessions/2026-05-14`?** **Answered (2026-06-11): rotate later, as the first
   step of L1.** Acceptable only on the presumption the key is inactive, since the leak is already in git
   history; L1 begins with the rotation + doc redaction.
1. **Guest network facts (ADR-0011)?** **Answered (2026-06-11), all four:** the cast target is an **Apple
   TV (AirPlay port set)**; the ISP plan is **300-700 Mbps** (borderline on the UDR's ~700 Mbps ceiling:
   measure throughput with and without IPS at setup, ADR-0013); a **guest SSID already exists** on the
   UDR (F0 restructures it and rotates the homelab passphrase guests may have historically received);
   **no printer** needs the Media/IoT treatment (the VLAN holds only the TV for now).
1. **The email tail (ADR-0012)?** **Answered (2026-06-11), all three:** the mailbox direction is
   **Proton, gated on S6 graduating** (Workspace stays canonical until the Bridge experiment proves
   itself; migration then runs under ADR-0007 standard class with the Drive/Docs/Meet coupling resolved
   at that point); forwarding scope is **forward-everything** (Elaine's triage is the filter; clawmail
   handles security filtering); **Stage 2 (apex MX) is decided only after Stage 1 data**, and may be
   mooted entirely if the mailbox moves to Proton (Proton would hold the MX and auto-forward).

All eleven questions were answered and locked on 2026-06-11; the consequences are propagated through the
changelog (item 3), ADR-0008 (reversed), ADR-0011/0012 (locked facts), the service matrix, and the
experiments backlog. Publication does not establish implementation readiness; the source dependencies and
current gates above still apply.

______________________________________________________________________

## Research appendix (primary sources)

Claims in this plan and the matrix trace to these sources (fetched 2026-06-10/11; release dates verified
via project APIs where stated). Maturity signals (latest release + date, cadence, license) are recorded
per candidate in the service matrix.

- **Promtail EOL / Alloy:** grafana.com/docs/loki/latest/send-data/promtail/ ("end of life as of March 2,
  2026"; Alloy migration tool).
- **Actual Budget:** actualbudget.org/docs (budgeting, backup-restore, install/docker, migration/ynab4,
  bank-sync); v26.6.0 (2026-06-01), MIT. **Firefly III:** docs.firefly-iii.org (export page's own backup
  warning; anti-zero-based-budgeting background); v6.6.3 (2026-05-21), AGPL. **SimpleFIN:**
  beta-bridge.simplefin.org ($1.50/mo, $15/yr).
- **KeePassium:** keepassium.com/pricing, github.com/keepassium/KeePassium (GPLv3; active 2026-05-23).
  **Strongbox:** strongboxsafe.com/strongbox-joins-applause/ (2025-03-13); repo stale since 2025-11-05.
  **Vaultwarden:** github.com/dani-garcia/vaultwarden (1.36.0, 2026-05-03; backup wiki).
- **Paperless-ngx:** docs.paperless-ngx.com + github releases (v2.20.15, 2026-04-27; v3 beta rc1
  2026-05-05 with breaking changes; document_exporter; arm64 manifest verified). **Immich:**
  docs.immich.app (requirements: 6GB min; backup-and-restore; v2.0.0 stable 2025-10-01; v2.7.x current).
  **Stirling-PDF:** repo README/LICENSE (open-core carve-outs).
- **Forgejo:** codeberg.org/forgejo (v15.0.3 + v11 LTS line, 2026-06-10; GPL-3.0+ since v9; upgrade doc's
  dump-restore caveat), forgejo.org/compare-to-gitea/ (interested party, flagged as such). **Gitea:**
  blog.gitea.com (Gitea Ltd, Enterprise). **Woodpecker:** v3.15.0 (2026-05-28), Apache-2.0. **Renovate:**
  docs.renovatebot.com/modules/platform/forgejo/ (official platform support); v43.x daily cadence, AGPL.
- **LiteLLM:** docs.litellm.ai/docs/proxy/prod (1 CPU/4GB per worker; Postgres for keys/spend), MIT core
  \+ enterprise/ carve-out. **Langfuse:** langfuse.com/self-hosting (v3 architecture: Postgres +
  ClickHouse + Redis + S3; 4-core/16GB compose guidance). **Ollama:** github.com/ollama/ollama (v0.30.x,
  MIT; no official CPU benchmarks, tok/s uncertain). **SearXNG:** docs.searxng.org (rolling release;
  limiter optional for private instances), AGPL.
- **Authelia:** authelia.com/configuration/first-factor/file/ (file backend first-class; argon2id); OIDC
  provider roadmap still beta; v4.39.20 (2026-05-26), Apache-2.0. **Pocket ID:** pocket-id.org/docs
  (OIDC-only; passkeys; v2.8.0 2026-05-31, BSD-2). **Wazuh:**
  documentation.wazuh.com/current/quickstart.html (4 vCPU / 8GiB / 50GB for 1-25 agents); v4.14.5
  (2026-04-23).
- **Pi 5 16GB:** raspberrypi.com announcement (2025-01-09, $120; BCM2712 D0); M.2 HAT+ official product
  page. **Podman quadlets:** docs.podman.io podman-systemd.unit(5). **arm64 images:**
  Prometheus/Alertmanager release tarballs; grafana/grafana + grafana/loki Docker Hub manifests.
- **Vikunja:** v2.3.0 (2026-04-09), AGPL; CalDAV self-described alpha; Todoist importer documented.
  **Donetick** v0.1.75 (pre-1.0). **Radicale** v3.7.4 (2026-05-28; flat-file storage). **Baikal** 0.11.1
  (slower cadence).
- **Internal:** PLAN-v11 (line-referenced critique), PLAN-OPENBAO.md, PLAN-ATUIN-SERVER.md,
  PLAN-RSS-FEED.md, docs/hardware/workstation-and-peripherals.md (2× Pi 5 16GB owned), dotfiles
  `docs-osquery-design` worktree (2026-06-09 v2 reshape design + implementation plan; Wazuh deferral;
  migration intent), dotfiles refactor plan (2026-06-10).

Uncertainty register: CPU tok/s for Ollama (no official benchmark); Authelia idle RSS (unpublished);
Forgejo RAM (Gitea's 1GB figure used as proxy); SimpleFIN bank coverage breadth; KeePassium free-tier
FaceID/OTP placement; Immich iOS background-upload reliability (Apple-scheduled); per-service RAM
estimates pending the deploy-time ledger.
