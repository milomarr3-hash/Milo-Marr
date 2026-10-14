# Uploading the te5 textures and filling TEX5

Pass 5 has 18 new textures, all code-generated PNGs of 1024² or smaller:

- 7 particle textures in `textures/te5/particles/`: shards, smoke, mote, glint, bokeh, streak and ash.
- 11 surface textures in `textures/te5/surfaces/`: dial inlay, sub-dial, accretion, galaxy floor/arms/core, engraving,
  halo, hairspring, stream and ribbon.

Their `manifest.json` files list each one's `texKey` (its key in the module's `TEX5` table) and `uploadedId` (still
`null`). Until a key has an id, the aura uses that texture's pass-4 fallback. So upload them **after** the first install
and look (README step 2d). That way any problem can be pinned on the code or on the textures.

They can only be uploaded from the Mac, because uploads need Milo's Roblox account in Studio.

## A. With the Studio MCP `upload_image` (how the Mac session uploaded pass 4)

`upload_image` takes `http://` URLs, so serve the texture folder on the Mac's own loopback address (nothing leaves the Mac).
Run this in the background and keep it running while you upload:

```sh
cd ~/Documents/Milo-Marr/textures/te5 && python3 -m http.server 8765 --bind 127.0.0.1
```

Then upload in batches of up to 5. The pass-4 uploads used 5 per call, and the big PNGs are about 1 MB each:

```
upload_image  imagePaths: ["http://127.0.0.1:8765/particles/te5_shards.png", "http://127.0.0.1:8765/particles/te5_smoke.png",
                           "http://127.0.0.1:8765/particles/te5_mote.png", "http://127.0.0.1:8765/particles/te5_glint.png",
                           "http://127.0.0.1:8765/particles/te5_bokeh.png"]
upload_image  imagePaths: [".../particles/te5_streak.png", ".../particles/te5_ash.png",
                           ".../surfaces/te5_dial_inlay.png", ".../surfaces/te5_subdial.png", ".../surfaces/te5_accretion.png"]
upload_image  imagePaths: [".../surfaces/te5_galaxy_floor.png", ".../surfaces/te5_galaxy_arms.png",
                           ".../surfaces/te5_galaxy_core.png", ".../surfaces/te5_engraving.png", ".../surfaces/te5_halo.png"]
upload_image  imagePaths: [".../surfaces/te5_hairspring.png", ".../surfaces/te5_stream.png", ".../surfaces/te5_ribbon.png"]
```

(`...` stands for `http://127.0.0.1:8765`. Always write the full URL.)

Each call returns a JSON map like `{"http://127.0.0.1:8765/particles/te5_mote.png": "rbxassetid://123...", ...}`. Save
**each result exactly as returned** to a file, for example `/tmp/te5_up1.json` to `/tmp/te5_up4.json`, and record them:

```sh
cd ~/Documents/Milo-Marr
python3 roblox/install/patch_tex5.py record --json /tmp/te5_up1.json
python3 roblox/install/patch_tex5.py record --json /tmp/te5_up2.json      # ... and so on
```

Then stop the web server (kill the background `http.server`).

## B. By hand with Studio's Asset Manager

1. In Studio, open **View -> Asset Manager** and click **Bulk Import**. Pick all 18 PNGs from `textures/te5/particles/`
   and `textures/te5/surfaces/`.
2. When they are done, open **Images** in the Asset Manager. Right-click each one, choose **Copy Asset ID**, and note
   which file it belongs to.
3. Record them. Any spelling of a texture works: the file name, the name, or the texKey:

```sh
python3 roblox/install/patch_tex5.py record te5_shards.png=rbxassetid://111 te5_smoke=222 mote=333 ...
```

## Then: fill TEX5, re-make the payloads, install

```sh
python3 roblox/install/patch_tex5.py status        # every texture should show an id under "manifest"
python3 roblox/install/patch_tex5.py patch         # fills TEX5 in roblox/ReplicatedStorage/AuraFX/TheEnd.lua
python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua --label pass5tex
```

Then install again: README step 2c (`01_backup` -> pieces -> `apply`), and test (`studio_checks.md`).

What the commands do:
- `record` writes the ids into `textures/te5/*/manifest.json` (`uploadedId`, as `rbxassetid://<digits>`) and rewrites
  `textures/te5/uploaded.md`, which lists every te5 id like `textures/te4/uploaded.md`. If a texture already has a
  **different** id it refuses and writes nothing. Re-uploading has to be deliberate: add `--force`.
- `patch` changes only the string values inside `local TEX5 = { ... }`. Nothing else in the module changes. It prints the
  new size and checksum. Running it twice is harmless (`0 changed`). Run `patch --check` to see whether the module is in
  step with the manifests.

## Notes

- **Moderation:** a new image can show as blank or grey until Roblox approves it. Wait a few minutes before judging how it
  looks in Play.
- **Re-uploading one texture** (for example a fix after a Studio check): edit or flip the PNG and upload just that file.
  Then run `record <file>=<new id> --force`, `patch`, `make_payloads.py ... --label pass5texN`, and install.
  - te5_streak: if the streaks fly tail-first (STUDIO-VERIFY: VelocityParallel puts the texture's top along the
    velocity), flip it with `python3 -c "from PIL import Image; p='textures/te5/particles/te5_streak.png'; Image.open(p).transpose(Image.FLIP_TOP_BOTTOM).save(p)"`
    and re-upload.
- **Re-running a texture generator** (`textures/te5/*/make_te5_*.py`) rewrites its manifest with `uploadedId: null`. The
  ids are still in `textures/te5/uploaded.md` and in the module's `TEX5`. Record them again from there.
- Record every id: `uploaded.md` and the manifests are the only record in the repo. Mention the new ids in
  `docs/memory/aura-rng.md` too.
