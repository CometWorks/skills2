# PluginHub-SE2 Flow

PluginHub-SE2 registers Space Engineers 2 client plugins for [Pulsar](https://github.com/SpaceGT/Pulsar). Pulsar Modern downloads the pinned GitHub commit and compiles it with Roslyn on the player's machine, so what ships is what the pinned source says, plus whatever the manifest's assets and NuGet packages bring in.

## Deterministic preparation

Run:

```bash
python3 scripts/prepare_review.py <PR-URL>
```

Use `--output <directory>` only when the default `~/.se2-dev/reviews/StarCpt-PluginHub-SE2-pr-<number>` location is unsuitable. The script:

1. Validates that the PR belongs to `StarCpt/PluginHub-SE2`.
2. Fetches PR base/head SHAs and changed `Plugins/*.xml` files through GitHub.
3. Parses complete base/head XML manifests, including every `<Asset>` element's attributes.
4. Checks the `xsi:type`: `GitHubPlugin`, or `ModPlugin` beneath `Plugins/Mods/` with a numeric Workshop `<Id>`. A `ModPlugin` gets `review_type: workshop_mod` with its `workshop_id`, `hidden` and `dependencies`, and no source checkout.
5. Reads `<RepoId>` and authoritative old/new `<Commit>` pins and resolves them to full target-repository SHAs.
6. Checks out the exact new source SHA.
7. Selects the audit gate from the manifest change in the hub PR. A first registration or changed `<RepoId>` writes `source-tree.txt` for the complete tracked repository at `new_source_sha`; only a real `<Commit>` bump writes `source.diff` and `changed-files.txt` from the direct `old-source-SHA..new-source-SHA` comparison.
8. Records package, build, binary, native-file, submodule, and static MSBuild-reference inventory in `review.json`.
9. Records `source.asset_checks`: for each manifest asset, whether its repository `Path` is a file, a folder, or missing at the pinned SHA, the file's actual SHA-256 against the declared `Sha256`, and every `Url` asset, which is not fetched.

Read the generated root and per-plugin `review.json` files before reviewing. Do not substitute the target repository's default branch or hub PR SHAs for manifest pins.
Require `source.audit_scope` to match `review_type`: `full_repository_tree` for `new_registration`, `direct_commit_diff` for `version_bump`. Stop if it does not. Never synthesize a new-registration diff against the target's parent, empty tree, default branch, or latest commit.
Treat `msbuild_references` as an audit index, not proof of the evaluated build graph: imports, conditions, SDK defaults, and generated files can add or remove references. Pulsar does not build the project file at all; see below.

A `metadata_only` result has no source checkout and no asset checks. If its manifest change adds or edits an `<Asset>`, check that asset at the pinned SHA by hand.

## Registry checks

Run the hub's own validator from the PR head checkout: `python3 test.py Plugins` must print `All files validated`. It checks only the location, `xsi:type`, the presence of `Id`, `FriendlyName`, and `Author`, and a lowercase-hex `Commit` for `GitHubPlugin`. Check the rest yourself:

- A `GitHubPlugin` uses a fresh GUID as `<Id>` and the GitHub `Owner/Repo` as `<RepoId>`. A `ModPlugin` uses the Steam Workshop item id as `<Id>`.
- A `ModPlugin` names a Steam Workshop item, not a GitHub revision, so there is nothing to pin, compile or diff. Review it with the `workshop_mod` checks in [ReviewPaths.md](ReviewPaths.md).
- `Hidden`, `DependencyIds`, `AlternateVersions`, `Runtimes`, `Platforms`, and `GroupId` are optional. Compare them with `SamplePlugin.xml` and `SampleMod.xml` at the hub head.

## Loader semantics

Trace what Pulsar Modern actually installs and compiles, not just what the XML says. Confirm these against the current Pulsar source (`Shared/Data/GitHubPlugin.cs`, `Shared/Assets/PluginAsset.cs`, `Shared/Assets/AssetResolver.cs`) when a finding depends on them:

- Omitted `SourceDirectories` means the whole repository compiles. When present, check that the required source is included and that tests, samples, and tooling are excluded.
- `NuGetReferences` are restored for the compile. Project-file `<PackageReference>` and `<Reference>` entries are not; the `.csproj` is only an IDE build.
- Each `<Asset Name="…">` is resolved either from a repository `Path` in the pinned source archive or from a `Url` downloaded at install time. `Name="AssetFolder"` is the path handed to a plugin's `LoadAssets(string)` method, and a `LoadAssets(IReadOnlyDictionary<string, string>)` method receives every asset by name. Audit the full content of each asset the plugin reads.
- `Reference="true"` copies the asset into the plugin's bin folder and passes it, or every managed DLL at the top level of a folder asset, to the compiler as a reference. Treat it like a committed binary in the compile closure: establish what it is, where it comes from, and why it is needed.
- `Sha256` is verified only for single-file assets, from the repository or a URL. A missing `Sha256` is just a log warning, and folder assets are never hashed. A `Url` asset is content outside the pinned source, so require a `Sha256`, a stable versioned URL, and provenance for what it downloads.
- `Extract="true"` unpacks an archive asset. Audit the archive's contents, not just its name.
- Assets and the plugin itself can be restricted with `Runtimes` and `Platforms`. Check which assets each platform actually receives.
- Each `AlternateVersions/Version` can name its own `Repo` and `Commit`. A player can select it, so a different repository there is a separate source to review.
- Resolve `DependencyIds` far enough to establish what is installed and loaded together.

The hub manifest is authoritative. Do not report a target repository's backup manifest `<Commit>` as stale. If a backup manifest exists, ignore its commit value but compare other loader-relevant fields such as source directories, NuGet references, assets, and dependencies for meaningful drift.

Then follow [ReviewPaths.md](ReviewPaths.md) and [ReviewPolicy.md](ReviewPolicy.md).
