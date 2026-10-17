# Installing THE END pass 5 into Roblox Studio

This kit puts `roblox/ReplicatedStorage/AuraFX/TheEnd.lua` (THE END's equipped aura, pass 5 "The Last Clock") into Milo's
place as `ReplicatedStorage.AuraFX.TheEnd`. It is made for **Milo's local Claude Code with the Roblox Studio MCP**
(`execute_luau`, `screen_capture`, `start_stop_play`, `upload_image`), and also works **by hand** (Studio's Command Bar).

It was written in a cloud session that has no Studio. It was tested only against a mock of the Studio APIs
(`test/run_tests.py`), so nothing here has been tested in Studio yet. The first real run is on the Mac.

Safety rules: the old module is backed up before anything changes, and nothing is ever deleted from
`ServerStorage.AuraRNG_Backups`. Every payload checks its own text, so a payload that gets changed on the way in is refused.
The new source is compile-checked before it is written, then read back and checked byte for byte. If anything doesn't
match, the old text is put back. Keep **HttpService OFF** (the kit doesn't need it). **Never publish** the place.

| file | what it is |
|---|---|
| `README.md` | this: the steps |
| `MILO_PROMPT.md` | the message Milo pastes into his local Claude Code |
| `make_payloads.py` | module file -> `payloads/` (run it before every install) |
| `payloads/` | `00_status`, `01_backup`, `02..` pieces, `NN_apply`, `90_install_from_file` (plan B), `99_rollback`, `manifest.json` |
| `upload_textures.md`, `patch_tex5.py` | upload the 29 te5 textures, record their ids, fill the module's `TEX5` table |
| `studio_checks.md` | the Play-mode test checklist with ready-to-run `execute_luau` snippets, and how to report back |
| `test/` | cloud tests: the payloads run in the luau CLI against `mock_studio.luau` |

## Before you start

- Roblox Studio is open on **Milo's place** (milos place), and the Studio MCP is connected.
- Studio is in **Edit mode**. Stop Play first: the install payloads refuse to run in Play.
- `python3` works in Terminal (the scripts only use its standard library).
- The whole install takes about 10 minutes: one backup payload, about 11 piece payloads of up to 18 KB (see the manifest order), then the apply.

## 1. Get the files onto the Mac

If the repo is not on the Mac yet:

```sh
cd ~/Documents
git clone https://github.com/milomarr3-hash/Milo-Marr
cd Milo-Marr
git checkout claude/loving-planck-hsidm6
```

If it is already cloned:

```sh
cd ~/Documents/Milo-Marr
git fetch
git checkout claude/loving-planck-hsidm6
git pull
```

All the paths below are relative to that folder.

## 2. Install the module (first with the fallback textures)

**2a. Make the payloads.** Always do this first, so they match the module file exactly:

```sh
python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua
```

It prints the module's size and checksum, and the payload list in run order. If `git status` then shows no changes under
`roblox/install/payloads/`, the payloads in the repo were already up to date. It also notes that `TEX5` is empty: that's
expected for now, because the aura falls back to pass-4 textures until step 3.

**2b. Optional: check what is live.** Run `payloads/00_status.luau`. It is read-only. It should say
`ReplicatedStorage.AuraFX.TheEnd is 35000 bytes, checksum 489406639 = the pass-4 live version`.

**2c. Run the payloads in order** (the list is in `payloads/manifest.json` under `order`):
`01_backup.luau`, then `02_chunk_01_of_NN.luau` ... `NN_chunk_NN_of_NN.luau`, then `NN_apply.luau`.

How to send one with the Studio MCP:
1. Print the file raw with `cat roblox/install/payloads/<file>`, taking the file names in the order `payloads/manifest.json`
   lists them under `order` (the first chunk is `02_chunk_01_of_NN.luau`; NN depends on the module's size). If you use the
   Read tool instead, leave out its line-number prefixes.
2. Call `execute_luau` with `datamodel_type: "Edit"` and `code` set to **exactly** that text. Tabs, blank lines, spaces
   and the last line all count. Don't reformat it, shorten it, or "fix" anything in it.
3. The result is one line: `OK <file>: ...`, `FAIL <file>: ...` or `STOP <file>: ...`. Only go on after an `OK`.

What the OK lines say:
- `01_backup`: the module's size and checksum, `the pass-4 live version`, then
  `Backed up to ServerStorage.AuraRNG_Backups.TheEnd_<YYYYMMDD>_before_pass5 (text checked)` and `Next: 02_chunk_01...`.
- Each piece: `piece k/N stored (... bytes, checksum ...). The holder has k/N. Next: ...`.
- `apply`: `installed: ReplicatedStorage.AuraFX.TheEnd is now <bytes> bytes, checksum <n> (compiled, written, read back
  from the editor and checked). The previous version is saved as ...`. Those numbers must match what `make_payloads.py`
  printed and `payloads/manifest.json` -> `source`.

If something goes wrong:

| result | what to do |
|---|---|
| `STOP ... Play mode` | Stop Play (`start_stop_play` with `is_start: false`) and run the same payload again |
| `FAIL ... arrived changed` | The payload's text was changed on the way. Nothing was stored. Send the same file again, exactly. If it keeps failing, make smaller payloads (`make_payloads.py ... --max-bytes 12000`) and start again at `01_backup`, or use plan B |
| `FAIL ... piece k is missing` | Run the payload it names first (pieces go in order). Running a piece twice is fine |
| `FAIL ... no install holder` | Run `01_backup.luau` of the same payload set first (after re-running `make_payloads.py`, always start again at 01) |
| `FAIL ... changed after 01_backup.luau ran` | The live module was edited after the backup. Run `01_backup.luau` again (it makes a second backup), then `apply` |
| `FAIL ... does not compile` | The module has a Luau syntax error. Nothing changed. Tell Milo and report the error (cloud side fixes it) |
| `FAIL ... read back different` / `UpdateSourceAsync failed` | Studio stored something else. The old text was put back and checked (it says so). Report the message |
| `FAIL ... WARNING: the previous version could not be put back` | Run `99_rollback.luau` now, then report |
| `FAIL ... Lua error` | Report the message. Run `00_status.luau` to see the state |

**2d. Quick look with the fallback textures.** Do steps 1 and 2 of `studio_checks.md` (equip, day and night shots), so we
know the module runs before the new textures go in. Show Milo the thumbnails.

### Plan B: install from a file dialog (no big payloads)

`payloads/90_install_from_file.luau` is about 7 KB and does the whole install in one go. It backs up the live module like
01, then opens a file dialog **on the Mac** (`StudioService:PromptImportFileAsync`). Someone picks
`roblox/ReplicatedStorage/AuraFX/TheEnd.lua` from the repo clone, and the payload checks it is exactly the file
`make_payloads.py` saw (size + checksum). Then it compiles it, writes it, reads it back and checks it. Use it if the piece
payloads keep arriving changed. Milo has to click in the dialog, and the MCP call might time out while it waits. If so,
run it from the Command Bar instead.

### By hand (without Claude)

1. In Terminal, run `python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua`.
2. In Studio (Edit mode), open **View -> Command Bar**. Open `roblox/install/payloads/90_install_from_file.luau` in a text
   editor, copy all of it, paste it into the Command Bar and press Enter. Pick `TheEnd.lua` in the dialog.
3. The result line appears in the **Output** window. It must start with `OK`.

## 3. Upload the new textures, fill TEX5, install again

Follow **`upload_textures.md`**. In short: serve `textures/te5/` on `127.0.0.1` and send the 29 PNGs with `upload_image`, or
use Asset Manager -> Bulk Import. Then run `patch_tex5.py record`, then `patch_tex5.py patch`. Then make the payloads
again with a new label and repeat step 2c:

```sh
python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua --label pass5tex
```

`01_backup` then saves the fallback-texture version as `TheEnd_<date>_before_pass5tex`. The pass-4 backup stays where it is.

## 4. Test in Play

Follow **`studio_checks.md`**. It covers day and night from the calibrated "studio" camera, the owner view, close and far,
movement, the Highlight, low quality, other players, the film-mesh flags, performance, and the STUDIO-VERIFY items. It
ends with how to report back (`docs/the-end/pass5-studio-results.md`) and what to update in `docs/memory/aura-rng.md`.

## 5. Roll back (if pass 5 has to come out)

Run `payloads/99_rollback.luau` in Edit mode. By default it puts back **the pass-4 live version** (the backup with 35000
bytes, checksum 489406639). If there isn't one, it uses the newest backup this kit made. Before it writes, it saves the
version being replaced as `TheEnd_<date>_replaced_by_rollback`, so nothing is lost. To restore a different backup, set
`local BACKUP_NAME = "..."` at the top of the file to one of the names `00_status.luau` lists. Running the rollback twice
is harmless (`already rolled back`). CONFIG attributes on the module (film-mesh flags and so on) are not touched; pass 4
ignores them.

By hand: in the Explorer, open `ServerStorage.AuraRNG_Backups.TheEnd_<date>_before_pass5`. Select all its text, copy it,
open `ReplicatedStorage.AuraFX.TheEnd`, select all and paste. Then run `00_status.luau` in the Command Bar. It must say
`35000 bytes, checksum 489406639 = the pass-4 live version`.

## Reference

- **Checksum:** `x = (x * 131 + byte) % 1000000007` over the file's bytes, starting from `x = 0`. It's the same number the
  Mac session's install scripts printed. Pass-4 live: **35000 bytes, checksum 489406639**
  (`roblox/ReplicatedStorage/AuraFX/TheEnd.pass4-live.lua`). The new module's numbers are in `payloads/manifest.json`
  -> `source`, and `make_payloads.py` prints them.
- **In Studio:** `ServerStorage.AuraRNG_Backups` holds the backups. It is made if missing and nothing is ever deleted from
  it. Each backup has `AuraRNG_BackupOf`, `AuraRNG_Length`, `AuraRNG_Checksum` and `AuraRNG_SavedAt` attributes.
  `ServerStorage.AuraRNG_Install` is the temporary holder (one StringValue per piece). The apply step removes it.
- **Saving:** the install changes the open place. Milo decides when to save it. Don't publish.
- **Up to date?** Run `python3 roblox/install/make_payloads.py roblox/ReplicatedStorage/AuraFX/TheEnd.lua --check`. It
  exits 1 if `payloads/` doesn't match the module.
- **Options:** `--label` (backup suffix), `--before FILE|none` (the version expected live, default
  `TheEnd.pass4-live.lua`), `--max-bytes` (default 18000, the size of the largest payload the Mac session has sent;
  up to 20000 is fine), `--target`.
- **Cloud tests:** run `python3 roblox/install/test/run_tests.py` (needs the luau CLI, `LUAU_BIN`). It installs the real
  modules, a ~150 KB module, and a module full of multi-byte characters and `]==]` sequences cut at many piece sizes,
  then dumps the installed text out of the mock and compares it byte for byte. It also covers every failure path above,
  plan B, rollback and `patch_tex5.py`. It runs the `studio_checks.md` snippets in the aura harness's mock world next
  to the real module. With `LUAU_LSP` set, it type-checks every payload and snippet against Roblox's API. It proves the
  payload logic, not Studio's behaviour.
