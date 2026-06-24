# Orchestra membership — bourse

> **This project (bourse) is a MEMBER of the Orchestra** (one coordination
> structure; reconciled 2026-06-03). The leader-node is **ORCHESTRA_dev**
> (governance, roster, contracts, TACI, publication); the technical inference hub
> is **flexyBayes** (the dependency-DAG sink). This file is bourse's back-pointer
> to that charter and a map of my siblings.

- **My role:** the **grounded market-data connector** — the trading arm's data
  collector. Read-only market-data result types (`market_series` OHLCV,
  `order_book` L2, `market_ticker`) from a public exchange, each carrying a
  grounding token + per-column `obs_schema`. The trading-domain analogue of
  terroir: a producer, never an analytics layer (no returns/resampling/spread —
  those are downstream consumers').
- **Contracts I own / honour:** I emit **no manifest** (a raw-feed connector
  upstream of the manifest-emitting members); I integrate via the **grounding-token
  + obs_schema** contract. `bourse_catalogue_diff()` is the only `[unverified]→
  grounded` move (diffing asserted facts against the exchange's own
  `/exchangeInfo`). `combine_grounding` is a worst-case monoid (an unverified feed
  taints the whole pipeline).
- **My edge:** producer — bourse → kalmix (OU / state-space) → proxymix → decideR
  (position sizing). The returns/resampling step is deliberately offloaded to
  those consumers. Acyclic: upstream of the modelling/decision layers.
- **What binds me (charter invariants):** *single-responsibility* (data, not
  analytics); **IOP-from-day-one** — recorded-real hash-pinned cassettes
  (sha256+md5 tamper meta-oracle, 90-day re-grounding), refuse-on-unverified
  (`bourse_refusal`); the grounding protects **capital** via decideR's firewall
  (the highest-stakes oracle in the federation); *leader-directed adoption*.
- **Governance:** bourse is a **Max-owned personal package** (`max578`, PRIVATE,
  MIT-track); the AAGI-AUS canon does not apply. The trading arm is a second domain
  sharing the engine (vision evolution unratified — see `vision_for_review.md`).

## My siblings (the full roster — so I am informed about the others)

| Member | Role | Class |
|---|---|---|
| flexyBayes | inference hub (owns C1/C4/C5/C7) | open (AAGI-gated) |
| PESTO | calibration + manifest source (C2) | open |
| kernR | validation + TACI/ACI engine | open |
| proxymix | KL-optimal proxy compression; the `proxymix_map` optimisation engine | open |
| gretaR | engine — torch MCMC | open |
| koine | synthesis — fourth opinion | open |
| terroir | data collector (C6) | open (MIT) |
| kalmix | state-space / change-point / ACI | open (MIT) |
| masque | data sovereignty (clones) | open |
| apsimR | external engine — APSIM Next Gen | open (MIT-src) |
| bourse | **grounded market-data connector (this package; the trading arm)** | open |
| survkit | time-to-event toolkit | open |
| janusplot | asymmetric GAM association matrices (diagnostic-viz) | open |
| gpfield | change-of-support spatial GP; emits `orchestra_manifest` | open (MIT) |
| decideR | decision layer (loss-optimal closer) | open |
| grainPlan | grain decision-orchestration (on decideR) | open (MIT) |
| optimix | optimisation meta-layer; emits `orchestra_manifest` | open (MIT) |
| flexyBayesOrchestra | composition layer (surrogates, koine backend) | open |

Planned: genoR. **Canonical charter:** `ORCHESTRA_dev/ORCHESTRA.md` (mirrored in
the MaxAIbase brain, open tier). **Contract + dependency DAG:**
`ORCHESTRA_dev/integration/orchestra_manifest.R`.
