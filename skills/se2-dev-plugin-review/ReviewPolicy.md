# Plugin Review Policy

Use judgment, not keyword matching. Space Engineers 2 plugins execute unsandboxed with the player's authority, so code must remain understandable enough to audit.

## Security and supply chain

- Establish repository provenance: public availability, declared author/repository relationship, license, default branch, pin reachability from that branch, tags/releases when claimed, and any drift between the pin and repository HEAD. An orphaned or rewrite-prone pin is a distribution-availability risk even when its contents review cleanly.
- Manually trace every in-scope path involving dynamic assembly/code loading, externally selected types passed to `Activator.CreateInstance`, reflection driven by external input, process execution, shell commands, networking, credentials, identifiers, local files, serialization, cryptography, or decoded/compressed payloads.
- Enumerate every contacted host and the data sent. Reject unexplained telemetry, exfiltration, remote-controlled commands, or hidden endpoints.
- Judge the complete flow rather than a keyword: opening a fixed HTTPS URL in the browser is not arbitrary process execution; DPAPI-protected local credentials and base64/GZip data are not code execution unless their output reaches an execution or unsafe deserialization sink.
- Inspect new or changed package references, lock files, restore sources, build targets, scripts, and generated code. Confirm each dependency is necessary and that registry metadata supplies dependencies needed by the loader's source compiler.
- Enumerate assembly, project, package, framework, COM, and analyzer references from project files and imported props/targets. For each unfamiliar reference, establish its authoritative origin, version, source usage, and whether it enters the hub loader's compile/runtime closure. Resolve property-based `HintPath` values far enough to classify them as game/SDK/tool installation, package cache, repository file, or machine-specific path. `Private=False`, a familiar filename, or successful compilation is not provenance.
- Distinguish IDE-only references from loader dependencies. Pulsar's source compilation does not consume project-file `<Reference>` or `<PackageReference>` entries; required non-game dependencies must be declared in hub metadata as `NuGetReferences` or `Reference="true"` assets. Unused game-install references are build-file noise, not shipped plugin binaries, but still report that they were checked.
- Reject unexplained committed executables, managed DLLs, or native libraries, whether loaded by plugin code or handed to the compiler as a `Reference="true"` asset. Prefer a hub `NuGetReferences` dependency over a committed library. If an exceptional binary is necessary, establish its authoritative origin and verify it byte-for-byte against the exact official package or release artifact; a matching name/version or signature alone is insufficient, and unverifiable code is not reviewable.
- A `Url` asset is code or data outside the pinned source. Require a `Sha256`, a stable versioned URL, and an authoritative origin for its content; a folder asset is never hash-checked by Pulsar, so read it.
- Reject self-updating code. Registry commit pins and the loader owns updates.
- Reject obfuscation, encoded indirection, or spaghetti that prevents confident review.
- AI/scanner output can direct attention but cannot replace reading the actual source. The human maintainer owns final security judgment and approval.

## Multiplayer fairness

Ask what information or action a vanilla player could obtain in the same situation.

- Client-side plugins, including plugins that alter local physics or prediction, are allowed. Do not report a finding merely because behavior is client-only, non-authoritative, or documented as not multiplayer-safe; the server is normally authoritative and rejects or corrects local state.
- Report multiplayer security/fairness risk only when a concrete path can break server authority: for example, the server accepts or rebroadcasts an unauthorized state/action, validation can be bypassed, hidden server data becomes available, or harmful synchronized state persists. Name that path and evidence. Keep unverified authority behavior in the human checklist, not the PR findings.
- If vanilla provides no legitimate route to server-observable information or action, and the plugin has a concrete path past server authority, presume the feature is too cheaty until a convincing, enforceable justification is demonstrated.
- Check ownership, relation, access, safe-zone, visibility, replication, spectator, camera, voxel, inventory, and entity boundaries relevant to the feature. Verify each against the SE2 game code; do not assume an SE1 mechanism exists in SE2.
- For uploaded or exported grids, blueprints, or telemetry, trace owner IDs, Steam IDs, GPS/private coordinates, and other embedded player data; remove fields the legitimate destination does not require.
- Client-side UI or input gates are not server authority. Do not treat them as enforcement when a modified client can bypass them.
- Automation and presentation are not automatically cheating; judge whether they reveal hidden state, bypass gameplay constraints, or perform actions beyond the player's legitimate authority.
- When fairness is ambiguous, ask a short, concrete question describing the exact vanilla comparison, suspected server-authority path, and multiplayer consequence; do not present suspicion alone as a finding.

## Filesystem and persistence

- Use `Singleton<VRageCore>.Instance.AppDataPath` (`Keen.VRage.Core`) for user data. Do not use `Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData)` or a hard-coded home-directory path, because Space Engineers 2 supports the `-appData:<path>` launch argument. Confirm the current API with `se2-dev-game-code` before reporting a path as wrong.
- Do not modify installed game files or mod files on disk. Removing a misbehaving plugin must be enough to stop its persistent effects.
- Keep configuration and generated data under a plugin-owned location beneath the game user-data path.
- Treat arbitrary file access, broad path traversal, insecure temporary files, and non-atomic destructive writes as security or data-loss risks.

## Compatibility, performance, and maintainability

- Check the hub and prior review thread for plugins with overlapping features, Harmony targets, UI locations, assets, files, global state, or host lifecycle hooks. Test a concrete overlap when evidence suggests one; do not invent a compatibility requirement from superficial similarity.
- Do not clobber other plugins: use unique Harmony IDs, narrow patch targets, undo registrations/patches on dispose, preserve shared state, and avoid replacing global handlers when composition is possible.
- Do not noticeably degrade performance without a feature-level reason. Inspect hot hooks for repeated reflection, allocation, logging, scans, locks, blocking I/O, unbounded queues, and unsafe background access to game objects.
- Fail safely across lifecycle transitions: world load/unload, reconnect, host/client differences, null singleton windows, partial initialization, and plugin disable/reload.
- Prefer direct, boring code. Flag needless complexity only when it increases audit cost, bug risk, or compatibility risk; omit taste-only feedback.
- Swallowed exceptions are acceptable only for narrowly understood, genuinely optional behavior. Otherwise preserve enough context to diagnose failure.

## Evidence and stopping rules

- Distinguish `verified`, `not present in the reviewed scope`, `not run`, and `unable to verify`.
- A normal build does not prove loader compilation or runtime loading.
- Record exact compiler/loader settings, warnings, and errors for a reproduced source build. Name the loader source/version or installed compiler used to establish those settings.
- For a Pulsar Modern dev-folder test, confirm the loader selected the intended source, performed a from-source build (`DebugBuild=true`), and reached plugin `Init` without compiler errors or exceptions. A dev folder resolves assets from the working tree without hash checks, so it does not prove the hub path's asset handling.
- If source publicizes game assemblies, verify the loader-selected source supplies `IgnoresAccessChecksToAttribute`; an MSBuild-only Krafs.Publicizer injection does not exist on the registry Roslyn path. The `se2-dev-plugin` skill's `Publicizer.md` covers this.
- On version-bump re-review, verify the new hub head and source pin, reconcile prior material findings, and repeat checks affected by the delta. Do not carry a prior pass forward without checking that its assumptions remain intact.
- Read the PR review thread for prior findings and confirm fixes are included in the new authoritative pin. Report stale documentation or comments about changed behavior as non-blocking when they can materially mislead maintainers or users.
- Absence of a search hit does not prove absence of a security issue.
- Unavailable source, mismatched pins, unexplained binaries, or security-critical behavior that cannot be understood are blockers, not assumptions to waive.
- Keep feedback short, but do not compress away threat model, exploitability, affected data, or required remediation for a security finding.
