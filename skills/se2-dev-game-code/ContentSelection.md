# Which Game Content Is Copied

`Data/Content` is not a copy of the game's `Content` folder. `copy_content.py` walks a
fixed list of subfolders and, inside each, keeps only an allow-listed set of extensions.
Everything else is left in the game install.

The rule is **text in, binaries out**: `Data/Content` is committed to the local Git
repository so definition changes can be reviewed and diffed across game versions (see
[SKILL.md](SKILL.md#local-versioning-of-decompiled-sources)). Copying the binary assets
would put tens of gigabytes of opaque blobs into that history and make the diffs useless.

The reduction is drastic. In 2.4.0.77 roughly **51 GB of game content becomes ~88 MB**
across ~17,600 files — about 0.17%, and all of it reviewable text.

## Copied

| Extension | Where | What it is |
|-----------|-------|------------|
| `def` | all definition folders (see below) | JSON definitions of blocks, components, armor, characters, tools, environments, procedural bodies, ... |
| `loc-texts` | `MainMenuData` | JSON translation strings per language code |
| `json` | `System` | AI behaviour trees and system configuration |
| `fshash` | `Audio` | JSON index mapping FMOD bank file names to content GUIDs |

Folders searched for `def`: `Armors`, `ArmorSkins`, `Audio`, `BlockMaterials`,
`BlockTools`, `Blocks`, `CharacterTools`, `Characters`, `Colonization`, `Components`,
`Decals`, `Encounters`, `Environment`, `Items`, `MainMenuData`, `Materials`,
`Procedural`, `System`, `Templates`, `Textures`, `UI`.

A folder that does not exist in the installed version is reported as
`Skipping <name> (not found)` and is not an error — the list spans game versions, so
entries such as `Encounters` may be absent.

## Not copied

All of these are binary. None is greppable or diffable, so none belongs in a repository
whose purpose is reviewable text.

| Extension | What it is |
|-----------|------------|
| `dds` | GPU textures |
| `png` | images — many are DDS payloads despite the extension |
| `scm` | `VR3B` procedural asset |
| `vrm` | `VR3B` models |
| `wmv` | video — MP4 payload despite the extension |
| `bank` | FMOD sound banks |
| `vx2` | `VR3B` voxel data |
| `vra` | `VR3B` animations |
| `vrb` | `VR3B` content caches, at the top level of `Content` |
| `sbm` | `VR3B` legacy models |
| `armblock`, `armside` | `VR3B` armor block and side data |
| `hkt` | Havok physics tuning |

`VR3B` is Keen's own container magic; such a file starts with those four bytes.

## Consequences when searching

- A definition referencing a model, texture or sound resolves to a file that is **not**
  under `Data/Content`. The reference itself is visible in the `.def`; the asset is not.
  Look it up in the game install if you need the binary.
- `Data/CodeIndex/content_index.csv` covers only what was copied, so a binary asset never
  appears there even when C# code references it.
- Extension and payload disagree for some files (`png` holding DDS, `wmv` holding MP4).
  Trust the magic bytes rather than the name when this matters.

## Changing the selection

Edit the `copy_content(...)` calls in [copy_content.py](copy_content.py) and update this
page and [ContentTypes.md](ContentTypes.md) to match. A new extension only takes effect
on a re-copy: preparation skips the step when `Data/Content` already exists, so remove
that folder (or run `Clean.bat` / `clean.sh` and prepare again) to pick it up.
