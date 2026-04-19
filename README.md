[![DOI](https://zenodo.org/badge/1214466612.svg)](https://doi.org/10.5281/zenodo.19644945)
[![View Editor Session Commander on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://ch.mathworks.com/matlabcentral/fileexchange/183700-editor-session-commander)

# EditorSessionCommander

**EditorSessionCommander** is a lightweight tool for saving and restoring
MATLAB Editor sessions. It serves as the spiritual successor to
[EditorSessionManager](https://ch.mathworks.com/matlabcentral/fileexchange/46352-editor-session-manager),
based on that package but re-built to support the modern Chromium-based
desktop while maintaining full backward compatibility with the legacy
Java-based UI.

---

## Key Features

* **Modern UI Support:**
Seamlessly handles the new HTML5 layout engine and `tileCoverage` grid
logic.
* **Layout Fidelity:**
Restores exact tile proportions (weights) and file focus.
* **Hybrid Engine:**
Automatically detects your MATLAB version and uses the appropriate
internal API.
* **Legacy Compatible:**
Uses the same XML structure as its predecessors, allowing you to load
older session files.

---

## Usage

### 1. Direct Class Access
You can interact directly with the class for programmatic control:
```matlab
esc = EditorSessionCommander();
esc.saveSession('MyProject');
esc.openSession('MyProject');
```

### 2. Wrapper (Recommended for Projects)
A wrapper script is provided for quick execution. This is ideal for
start-up/shut-down routines of MATLAB projects:
```matlab
% Call from your project startup script
call_EditorSessionCommander('MyProject', 'load');
% Call before closing MATLAB
call_EditorSessionCommander('MyProject', 'save');
```

### 3. Custom Preferences Directory
By default, sessions are saved in `prefdir`. To use a custom location
(_e.g._, a cloud-synced folder or a project subfolder), use the included
custom `prefdir` function. It is called by the wrapper to override the
default path as an example.

---

## Compatibility & Requirements
EditorSessionCommander is designed to bridge several eras of the MATLAB
desktop. Compatibility depends on your specific release:

| Release Range | Desktop Engine | Status |
| :--- | :--- | :--- |
| **<= R2021a**         | Classic Desktop   | **Supported** (Legacy algorithm)       |
| **R2021b - R2022b**   | Classic Desktop   | **Unsupported** (Future work required) |
| **R2023a - R2024b**   | Classic Desktop   | **Unsupported** (Future work required) |
| **R2023a - R2024b**   | New Desktop (Beta)| **Supported** (Modern algorithm)       |
| **>= R2025a**         | New Desktop       | **Supported** (Modern algorithm)       |

> **Note:** In R2023a-R2024b, the "New Desktop" (Beta) must be active to
> use modern grid features. I have not identified how to patch the legacy
> algorithm to make it work past R2021a.

---

## Installation

> **Note:** Installation scripts are currently in beta for the modern version.

* **User Path:**
Run the included `install_in_user_path.m` to add the package to your static
MATLAB path.

* **Shortcuts:**
Run `create_shortcuts.m` to add "Save" and "Load" buttons to your MATLAB
toolstrip.

---

## Layout Limitations: Legacy vs. Modern
The legacy Java Editor allowed for "free-form" tiling where adjacent tiles
could have independent boundaries. The modern HTML5 Editor uses a
*strict grid*.

### Legacy (Flexible)
Adjacent tiles could have different widths:
```text
+-----------------------+
|        Tile 1         |
+-------------+---------+
|    Tile 2   |  Tile 3 |
+---------+---+---------+
| Tile 4  |    Tile 5   |
+---------+-------------+
```
### Modern (Strict Grid)
Tiles must align with the global column/row breakpoints:
```text
+-----------+-----------+
|        Tile 1         |
+-----------+-----------+
|  Tile 2   |  Tile 3   |
+-----------+-----------+
|  Tile 4   |  Tile 5   |
+-----------+-----------+
```

*EditorSessionCommander handles this by automatically calculating the
closest grid fit when loading legacy layouts.*