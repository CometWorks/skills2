import shutil
import sys
from pathlib import Path
from typing import Set

# Sits beside Decompiled rather than inside it: Decompiled holds only decompiled
# C# code. Content is versioned in the local Git repository all the same, so
# changes to the definition files can be reviewed across game versions.
CONTENT_DST = Path('Data') / 'Content'


def copy_content(content_root: Path, subdir: str, allowed_extensions: Set[str], exclude: Set[str] = ()):
    src_dir = content_root / subdir
    if not src_dir.exists():
        print(f"Skipping {subdir} (not found)")
        return

    dst_dir = CONTENT_DST / subdir
    dst_dir.mkdir(parents=True, exist_ok=True)
    count = 0
    for src_path in src_dir.glob('**/*'):
        if not src_path.is_file():
            continue

        src_path_ext = str(src_path).rsplit('.', 1)[-1].lower()
        if src_path_ext not in allowed_extensions:
            continue

        if any(part in exclude for part in src_path.parts):
            continue

        dst_path = dst_dir / src_path.relative_to(src_dir)
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src_path, dst_path)
        count += 1

    print(f"Copied {count} files from {subdir}")


def main():
    content_root = Path(sys.argv[1])
    assert content_root.is_dir()
    print(f"Content root: {content_root}")

    # Definition files (JSON-like format in SE2)
    copy_content(content_root, 'Armors', {'def'})
    copy_content(content_root, 'ArmorSkins', {'def'})
    copy_content(content_root, 'Audio', {'def'})
    copy_content(content_root, 'BlockMaterials', {'def'})
    copy_content(content_root, 'BlockTools', {'def'})
    copy_content(content_root, 'Blocks', {'def'})
    copy_content(content_root, 'CharacterTools', {'def'})
    copy_content(content_root, 'Characters', {'def'})
    copy_content(content_root, 'Colonization', {'def'})
    copy_content(content_root, 'Components', {'def'})
    copy_content(content_root, 'Decals', {'def'})
    copy_content(content_root, 'Encounters', {'def'})
    copy_content(content_root, 'Environment', {'def'})
    copy_content(content_root, 'Items', {'def'})
    copy_content(content_root, 'Materials', {'def'})
    copy_content(content_root, 'Templates', {'def'})
    copy_content(content_root, 'UI', {'def'})

    # Localization texts
    copy_content(content_root, 'MainMenuData', {'loc-texts'})

    # System configuration and AI
    copy_content(content_root, 'System', {'def', 'json'})


if __name__ == '__main__':
    main()
