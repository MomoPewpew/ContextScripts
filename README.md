# ContextScripts

Add Python scripts to Windows right-click context menu with automatic hierarchical organization based on folder structure.

## How It Works

The folder structure under `ContextScripts` determines the context menu hierarchy:

```
ContextScripts/
├── Codex/
│   └── Fix Paths/
│       ├── script.py
│       ├── script.bat
│       ├── install.bat
│       ├── uninstall.bat
│       └── requirements.txt
└── Utilities/
    └── File Organizer/
        ├── script.py
        └── ...
```

**Results in context menu:**
- Right-click in folder → Scripts → Codex → Fix Paths
- Right-click in folder → Scripts → Utilities → File Organizer

## Adding a New Script

1. **Copy an existing script directory** to your desired location under `ContextScripts`
2. **Edit `script.py`** with your new functionality
3. **Right-click `install.bat`** → **"Run as administrator"**

Your script will appear in the context menu at the location matching your folder structure.

## Script Structure

**`script.py`** - Your Python script that operates on the current directory:
```python
import os

def main():
    current_dir = os.getcwd()  # The folder where user right-clicked
    # Your script logic here...

if __name__ == "__main__":
    main()
```

**`script.bat`** - Handles Python execution and dependencies (already included in copies)

**`install.bat` / `uninstall.bat`** - Registry management (already included in copies)

**`requirements.txt`** - Optional Python dependencies

## Usage

1. Navigate to any folder in Windows Explorer
2. Right-click in the folder background
3. Scripts → [Your Menu Path] → [Script Name]
4. The script runs in that folder's context

## Key Features

- **Automatic hierarchy**: Folder structure = menu structure
- **Spaces supported**: "Fix Paths" folder becomes "Fix Paths" menu item
- **Clean uninstall**: Removes empty parent menus automatically
- **Admin required**: For registry modification only
- **Self-contained**: Each script directory is independent

## Troubleshooting

**"Must be run as Administrator"**
- Right-click `install.bat` → "Run as administrator"

**"Python is not installed"**
- Install Python from python.org and add to PATH

**"ContextScripts not found in path"**
- Ensure your script is in a subdirectory under `ContextScripts`

## Uninstalling

Right-click `uninstall.bat` → "Run as administrator" to remove the script from context menu and clean up empty parent menus.
