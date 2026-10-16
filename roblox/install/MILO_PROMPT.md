# Message for Milo's local Claude Code

Milo: copy everything inside the box below and paste it into Claude Code on your Mac. Open Roblox Studio with your place
first, with the Studio MCP connected.

```text
Hi! A cloud Claude session built pass 5 of THE END's equipped aura ("The Last Clock") plus an install kit. It could
not test anything in Studio, so you're the first to run it. Please:

1. Get the files. If ~/Documents/Milo-Marr exists: cd there, then git fetch, git checkout claude/loving-planck-hsidm6,
   git pull. If not: cd ~/Documents && git clone https://github.com/milomarr3-hash/Milo-Marr && cd Milo-Marr &&
   git checkout claude/loving-planck-hsidm6.
2. Read roblox/install/README.md and docs/memory/aura-rng.md, then install exactly as the README says. Studio must be in
   Edit mode. Run make_payloads.py first. Then send each payload with execute_luau (datamodel_type "Edit") as the file's
   exact text. Every result must start with OK before you go on; if not, follow the README's table. Never turn on
   HttpService, never publish, never delete anything in ServerStorage.AuraRNG_Backups.
3. Test it once with the fallback textures (studio_checks.md steps 1-2). Then upload the 20 te5 textures
   (roblox/install/upload_textures.md), record the ids, patch TEX5, re-make the payloads with --label pass5tex and
   install again.
4. Test in Play with roblox/install/studio_checks.md: day (ClockTime 14) and night (0.5) from the "studio" camera, the
   reveal, owner view, movement, low quality, other players and the rest of the checklist. Show me small thumbnails of
   the screenshots and tell me in plain words what you see and what changed.
5. Check every STUDIO-VERIFY item and write what really happened, including anything broken, in
   docs/the-end/pass5-studio-results.md (template in studio_checks.md). Only report what you actually saw.
6. Update docs/memory/aura-rng.md in the repo: what's installed now (bytes + checksum), the te5 texture ids, the
   results, and what's next. Update your own project memory too. Ask me before you commit or push.

If anything looks wrong or breaks the game, run roblox/install/payloads/99_rollback.luau to go back to pass 4, then
tell me.
```
