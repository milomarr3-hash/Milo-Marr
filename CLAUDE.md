# Milo-Marr — Claude notes

This repo is the cloud workspace for Milo's Roblox game **Aura RNG**. The game itself lives in Roblox Studio on Milo's Mac;
cloud sessions can't reach Studio, so they build code, textures and tools here for the Mac to install.

**Read `docs/memory/aura-rng.md` first** — it is the project memory (what the game is, Milo's exact direction, the aura
framework contract, asset ids, hard-won lessons). Keep it up to date at the end of each session.

Current focus: THE END's equipped aura, pass 5.1 (film-quality textures and particles) — `docs/the-end/` (status page:
`docs/the-end/README.md`), `roblox/ReplicatedStorage/AuraFX/`, `textures/te5/`. Built and checked in the cloud; waiting for
its first Studio test on Milo's Mac.

Pipeline: `tools/check_aura.sh MODULE OUTDIR` (harness + preview renders) → `tools/harness/tests/run_tests.py` and
`roblox/install/test/run_tests.py` → `roblox/install/make_payloads.py MODULE` (+ `--check`); details in `tools/README.md`.

## Layout

- `docs/memory/` — project memory for future sessions.
- `docs/the-end/` — THE END aura design docs (recovered art direction, pass-5 spec, status).
- `roblox/ReplicatedStorage/AuraFX/` — aura modules to install into Studio (`TheEnd.lua` = new pass; `*.pass4-live.lua` =
  exact copy of what is live now, for rollback/diffing).
- `roblox/install/` — how to install into Studio (from the Mac's Claude Code with the Studio MCP, or by hand).
- `textures/` — procedural texture generators (python3 + numpy + PIL) and their PNGs; ids are filled in after upload.
- `tools/` — cloud test tooling: a headless Luau harness that runs aura modules against a mock Roblox API, and a
  3D preview renderer.

## Rules for this project

- THE END is black, white and silver only. Keep the clock (Milo: "KEEP THE CLOCK THOUGH, ITS THE THEME").
  No flashes, strobes or flicker. It must read by day (bright cyan sky) and by night.
- Never claim something was tested in Studio unless it was. Cloud tests are headless (mock API + preview renders).
- Luau style: tabs, the pass-4 module's helpers and comment voice (short plain-English comments describing what you see).
- Don't commit Milo's personal info; this repo is public.
