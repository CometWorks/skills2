# Class and Interface Hierarchy Search

Search for inheritance relationships, interface implementations, and explore type hierarchies.

**IMPORTANT:** All hierarchy queries return only **direct** relationships (immediate parent/children). To traverse deep hierarchies, use multiple queries.

## Overview

The hierarchy system tracks:
- **Class inheritance** - Which classes inherit from which base classes
- **Interface inheritance** - Which interfaces extend other interfaces
- **Interface implementation** - Which classes/structs implement which interfaces

## Hierarchy Tree Files

Quick visual overview of the complete hierarchies:

- **`Data/CodeIndex/class_hierarchy.txt`** - Full class inheritance tree (large, do not load at once)
- **`Data/CodeIndex/interface_hierarchy.txt`** - Full interface inheritance tree (very large, do not load at once)

These files use tree-style formatting similar to the `tree` command with fully-qualified type names.

**Note:** Interface implementations are not shown in tree files. Use search commands for that.

## Search Commands

```bash
cd skills/se2-dev-game-code
uv run search_game_code.py <class|interface> <subcommand> <pattern>
```

### Class Hierarchy

#### Find Parent Class

```bash
uv run search_game_code.py class parent CubeGridComponent
```

Output: `Keen.Game2.Simulation.WorldObjects.CubeGrids.CubeGridComponent:Keen.VRage.Core.Game.Components.GameComponent`

Shows the direct base class. Classes with no explicit parent (inherit from `System.Object`) won't appear.

#### Find Child Classes

```bash
uv run search_game_code.py class children GameComponent
```

Output: `Keen.VRage.Core.Game.Components.GameComponent|Keen.Game2.Simulation.WorldObjects.(CubeGrids.(CubeGridComponent,CubeGridSplitterComponent),Characters.CharacterComponent)`

Shows all direct children in compressed namespace format.

#### Find Implemented Interfaces

```bash
uv run search_game_code.py class implements CubeGridComponent
```

Output: `Keen.Game2.Simulation.WorldObjects.CubeGrids.CubeGridComponent:Keen.VRage.Core.Game.Systems.IInSceneListener,Keen.Game2.Simulation.WorldObjects.Shared.IDisplayNameProvider`

Shows all interfaces implemented by the class.

### Interface Hierarchy

#### Find Parent Interface

```bash
uv run search_game_code.py interface parent IInSceneListener
```

Shows which interface this one extends.

#### Find Child Interfaces

```bash
uv run search_game_code.py interface children IInSceneListener
```

Shows all interfaces that extend this one.

#### Find Implementors

```bash
uv run search_game_code.py interface implementors IInSceneListener
```

Shows all classes/structs implementing the interface.

## Compressed Output Format

For queries that return multiple children/implementors, output uses hierarchical namespace compression:

- Groups by shared namespace prefixes
- Uses nested parentheses: `Namespace.(Child1,Child2)`
- Flattens single-child chains: `Namespace.SubNamespace.SingleChild`

Example:
```
A.B.(C.(Class1,Class2),D.Class3),X.Y.Class4
```

Means:
- `A.B.C.Class1`
- `A.B.C.Class2`
- `A.B.D.Class3`
- `X.Y.Class4`

## Common Options

All hierarchy commands support standard options:

```bash
-c, --count              Print only match count
-l N, --limit N          Limit to N results
-o N, --offset N         Skip first N results
-n NS, --namespace NS    Filter by namespace prefix
-i, --case-insensitive   Case-insensitive pattern matching
```

### Count Matches

```bash
uv run search_game_code.py -c interface implementors IInSceneListener
# Output: 47
```

For `parent` and `implements`: counts matching child types.
For `children` and `implementors`: counts matching parent types (not total children).

### Paginate Results

```bash
uv run search_game_code.py -l 10 interface implementors IInSceneListener
uv run search_game_code.py -l 10 -o 10 interface implementors IInSceneListener
```

### Filter by Namespace

```bash
uv run search_game_code.py -n Keen.Game2 class parent ""
uv run search_game_code.py -n Keen.VRage interface children IInSceneListener
```

## Pattern Syntax

Same as regular searches:

| Prefix | Behavior |
|--------|----------|
| `text:X` or just `X` | Case-sensitive substring match (use `-i` for case-insensitive) |
| `re:X` | Case-sensitive regex, Python regex syntax (use `-i` for case-insensitive) |

Multiple patterns use AND logic.

### Examples

```bash
# Find parent of any class matching pattern
uv run search_game_code.py class parent "re:.*BlockComponent$"

# Find children of classes ending with "Component"
uv run search_game_code.py class children "re:Component$"

# Find implementors of interfaces matching pattern
uv run search_game_code.py interface implementors "re:^I.*Listener$"
```

## Walking Hierarchies

To traverse deep hierarchies, chain multiple queries:

### Walk Up the Inheritance Chain

```bash
# Start with a class
uv run search_game_code.py class parent CubeGridComponent
# Output: Keen.Game2.Simulation.WorldObjects.CubeGrids.CubeGridComponent:Keen.VRage.Core.Game.Components.GameComponent

# Find its parent
uv run search_game_code.py class parent GameComponent
# Output: (no result — GameComponent inherits from System.Object)
```

### Walk Down the Inheritance Chain

```bash
# Find direct children
uv run search_game_code.py class children GameComponent

# Then query each child for their children
uv run search_game_code.py class children CubeGridComponent
```

### Explore Interface Hierarchies

```bash
# Walk up interface hierarchy
uv run search_game_code.py interface parent IInSceneListener

# Walk down interface hierarchy
uv run search_game_code.py interface children IInSceneListener
```

## Best Practices

1. **Start searching for what you already know** - Start by searching for what you already know from the task description
2. **Then drill down** - Use search commands for specific relationships
3. **Iterate for depth** - Each query returns only direct relationships
4. **Filter smartly** - Use `-n` to focus on specific namespaces
5. **Count first** - Check `-c` before fetching if you expect large result sets
6. **Combine searches** - After finding a class, use standard search to explore its members

## Next Steps

- **Standard searches**: See `CodeSearch.md` for finding methods, fields, etc.
- **Advanced techniques**: See `Advanced.md` for complex workflows
- **Technical details**: See `Implementation.md` for CSV structures and indexing
