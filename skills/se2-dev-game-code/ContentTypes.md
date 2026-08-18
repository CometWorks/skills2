File types under the `Data/Content` folder. Only the textual content is copied from
the game install; see [ContentSelection.md](ContentSelection.md) for the exact
inclusion rules and for the binary formats that are deliberately left out.

- `*.def` Definition File: JSON-based files that define game objects like blocks, components, armor pieces, characters, tools, environments, and other entities. This is the primary definition format in Space Engineers 2.
- `*.loc-texts` Localization Texts: JSON files containing translated text strings for the game's UI, organized by language code (e.g., `en-US`, `cz-CZ`). Includes block names, descriptions, categories, and other player-facing text.
- `*.json` JavaScript Object Notation: Used for AI behavior trees, system configuration, and other structured data.
- `*.fshash` FMOD Sound Hash Index: JSON file under `Audio` mapping each FMOD bank file name to its content GUID. Use it to resolve a bank referenced by GUID in code back to its file name.
