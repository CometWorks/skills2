# Code Search Guide

Search the decompiled Space Engineers 2 C# codebase efficiently.

**IMPORTANT:** This skill folder must be the current working directory. The commands
below are identical on Windows and Linux.

## Running Commands

Always change to this skill folder first:

```bash
cd skills/se2-dev-game-code
uv run search_game_code.py class declaration CubeGridComponent
```

## Search Categories

| Category | What It Searches |
|----------|-----------------|
| `class` | Class declarations and usages |
| `interface` | Interface declarations and usages |
| `struct` | Struct declarations and usages |
| `enum` | Enum declarations and usages |
| `enum_member` | Enum member declarations (usages count as usages of the enum) |
| `delegate` | Delegate declarations |
| `method` | Method declarations and usages |
| `field` | Field declarations and usages |
| `property` | Property declarations and usages |
| `event` | Event declarations and usages |
| `constructor` | Constructor declarations and usages |
| `namespace` | Namespace declarations and usages |

## Basic Usage

```bash
uv run search_game_code.py <category> <declaration|usage> <pattern>
```

### Find Declarations

```bash
uv run search_game_code.py class declaration CubeGridComponent
uv run search_game_code.py struct declaration Vector3D
uv run search_game_code.py interface declaration IInSceneListener
uv run search_game_code.py enum declaration BlockType
uv run search_game_code.py method declaration GetPosition
uv run search_game_code.py field declaration Position
uv run search_game_code.py property declaration IsWorking
uv run search_game_code.py event declaration OnClose
uv run search_game_code.py constructor declaration CubeGridComponent
```

### Find Usages

```bash
uv run search_game_code.py -l 10 class usage CubeGridComponent
uv run search_game_code.py -l 10 method usage GetPosition
uv run search_game_code.py -l 10 struct usage Vector3D
```

The pattern matches the used symbol itself, including usages inside method
bodies. The enclosing namespace, type and method are not searchable - to narrow
a usage search, filter by namespace with `-n` or grep the reported files.

### Search Method Signatures

Method signatures show the complete method declaration including modifiers, return type, parameters, and attributes:

```bash
# Find signatures by method name
uv run search_game_code.py method signature GetPosition

# Regex for exact match
uv run search_game_code.py method signature "re:^Update$"

# Limit results
uv run search_game_code.py -l 10 method signature GetPosition

# Filter by namespace
uv run search_game_code.py -n Keen.VRage method signature Normalize
```

**Output Format:** Signature searches show the full method signature after a pipe separator:
```
Game2.Simulation/Keen/Game2/Simulation/WorldObjects/CubeGrids/CubeGridComponent.cs:100-102|public static void DoSomething(int param)
```

**Note:** Signatures are always declarations. There is no `method signature usage` - use `method usage` instead to find method call sites.

**Note:** Patterns match the method *name*, not the signature text. The full
signature is only printed. Searching for a return type, parameter type or
attribute (`text:MTAThread`, `"text:string[] args"`) returns NO-MATCHES - grep
the declaration files for those instead.

## Search Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help |
| `-c`, `--count` | Print only match count |
| `-l N`, `--limit N` | Limit to N results |
| `-o N`, `--offset N` | Skip first N results |
| `-n NS`, `--namespace NS` | Filter by namespace prefix |

### Count Before Fetching

```bash
uv run search_game_code.py -c class usage CubeGridComponent
# Output: 103

uv run search_game_code.py -l 20 class usage CubeGridComponent
```

### Paginate Large Results

```bash
uv run search_game_code.py -l 20 class usage CubeGridComponent
uv run search_game_code.py -l 20 -o 20 class usage CubeGridComponent
uv run search_game_code.py -l 20 -o 40 class usage CubeGridComponent
```

### Filter by Namespace

```bash
uv run search_game_code.py -n Keen.Game2.Simulation class declaration ""
uv run search_game_code.py -n Keen.VRage method declaration Add
```

## Pattern Syntax

Patterns match against the symbol name (not namespace):

| Prefix | Behavior |
|--------|----------|
| `text:X` or just `X` | Case-sensitive substring match (use `-i` for case-insensitive) |
| `re:X` | Case-sensitive regex, Python regex syntax (use `-i` for case-insensitive) |

Multiple patterns use AND logic (all must match).

### Examples

```bash
# Substring match (default)
uv run search_game_code.py class declaration Block

# Explicit text match
uv run search_game_code.py class declaration "text:Block"

# Regex for exact match
uv run search_game_code.py class declaration "re:^CubeGridComponent$"

# Regex patterns
uv run search_game_code.py class declaration "re:.*BlockComponent$"
uv run search_game_code.py method declaration "re:^Get.*Position$"
uv run search_game_code.py struct declaration "re:^Vector[23]D$"
```

### Multiple Patterns

```bash
uv run search_game_code.py method declaration Get Position
```

Both "Get" AND "Position" must appear in the name.

## Reading Output

### No Matches
```
NO-MATCHES
```

### Standard Output
```
relative_path:line
relative_path:start-end
```

Lines are inclusive (both start and end are part of the match).

Results are sorted by code depth, then alphabetically.

### Reading Source Files

The `relative_path` is relative to the `Data/Decompiled/` folder:

```bash
# Search result: VRage.Core/VRage/Core/Vector3D.cs:13-2293
# Read file: Data/Decompiled/VRage.Core/VRage/Core/Vector3D.cs
```

The first folder indicates the assembly (DLL). From the second level, folders match namespace hierarchy.

## Assembly Reference

| Assembly | Contains |
|----------|----------|
| `VRage.Core` | Core types, math, utilities |
| `VRage.Core.Game` | Core game framework |
| `VRage.Game` | Game definitions, object builders |
| `VRage.Library` | Core library utilities |
| `Game2.Game` | Game logic and entity components |
| `Game2.Simulation` | Simulation logic, world objects, cube grids |
| `Game2.Client` | Client-side game code |
| `Game2.AutoTests` | Automated tests |

## Best Practices

1. **Start with declarations** - Find definitions before usages
2. **Use regex for exact names** - `"re:^Vector3D$"` avoids Vector3DI, Vector3D_Extensions, etc.
3. **Check the assembly** - First folder in path shows which DLL
4. **Count first** - Use `-c` to see match count before fetching all
5. **Paginate large results** - Use `-l` and `-o` for incremental browsing
6. **Query at most 10-20 results** - Keep context manageable

## Next Steps

- **Hierarchy searches**: See `HierarchySearch.md` for class/interface relationships
- **Advanced patterns**: See `Advanced.md` for complex regex and workflows
- **Technical details**: See `Implementation.md` for CSV structures and internals
