[![Buy me a coffee](https://img.shields.io/badge/-%20-FFDD00?logo=buymeacoffee&logoColor=black&logoSize=auto&style=flat-square)](https://buymeacoffee.com/tplobo)[![Buy me a coffee label](https://img.shields.io/badge/-Buy%20me%20a%20coffee-57606A?style=flat-square)](https://buymeacoffee.com/tplobo)
&emsp;&emsp;
[![File Exchange](https://img.shields.io/badge/-File%20Exchange-D95319?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjggMTI4Ij48cGF0aCBmaWxsPSIjZmZmIiBkPSJNMTIzLjk2NSA5MS45MDJjLTcuMjQ2LTE4LjI5Ny0xMy4yNjItMzcuMDU4LTIwLjE4NC01NS40NzYtMy4wNTQtNy44NC02LjA0Ny0xNS43NDYtMTAuMjE1LTIzLjA4Mi0xLjY1Ni0yLjYzMy0zLjIzOC01LjUyOC01Ljk1My03LjIxNWE0LjAxMyA0LjAxMyAwIDAwLTIuMjIyLS42MDZjLTEuMjcuMDI4LTIuNTM2LjU5NC0zLjUwNCAxLjQxNS0zLjY0NSAyLjg4Ni01LjgwNSA3LjA4Mi04LjIyNyAxMC45NDktNC4yNzcgNy4xNzItOC43ODkgMTQuNjg3LTE1Ljk0MSAxOS4zNDctMy4zNiAyLjM3MS03Ljc2MiAyLjYzLTExIDUuMTcyLTQuNDMgMy4zNC03LjQ0MiA4LjA3OC0xMS4wNzQgMTIuMTg0LS44MjkuOTg4LTIuMTEgMS4zODMtMy4yMjcgMS45MThDMjEuNTc4IDYwLjkzIDEwLjczOCA2NS4zMzYgMCA2OS45OGM5LjA5IDcuMDMyIDE4Ljc3NyAxMy4yOSAyOC4wNSAyMC4wNzkgMi41NDQtLjUwNCA1LjA5OC0xLjU0NyA3LjcyLTEuMDgyIDQuMTYgMS4zIDYuNTk3IDUuMjg1IDguNTAzIDguOTMgMy44NzUgNy45NCA2LjY3NiAxNi4zMjMgOS44MTMgMjQuNTcgNS4yNDYtLjM3NSA5Ljk2OS0zLjA3OSAxNC4wMjctNi4yNTggNy44MDktNi4zMjQgMTMuNzU4LTE0LjUgMjAuMzA1LTIyLjA0NyAzLjE0LTMuMyA2LjM0LTcuMjMgMTEuMDUtOC4xNDkgNC43NjItMS4xNTIgOS44NjQuNTU1IDEzLjM5NSAzLjgzNiA0Ljk1NyA0LjQzIDkuMzQ0IDkuNTUxIDE1LjEzNyAxMi45NDItLjc3Ny0zLjgzNi0yLjY0NS03LjI3OC00LjAzNS0xMC44OTl6TTQyLjk2IDc5LjAxMmMtNC41NyAyLjcwMy05LjQyNiA0LjkzLTE0LjE3NiA3LjI4OS03LjQ1Ny00Ljk5Ni0xNC43MjMtMTAuMjktMjIuMDUtMTUuNDY1IDkuODc4LTQuMzI4IDE5LjkxLTguMzQ4IDI5LjkxNy0xMi4zODcgNC43NDYgMy43MDMgOS42MzcgNy4yMjMgMTQuMzgzIDEwLjkyNi0yLjIzIDMuNTYzLTQuOTE0IDYuODcxLTguMDc0IDkuNjM3em0xMC4xNjgtMTIuNDE0QzQ4LjQxNCA2My4wNTggNDMuNjQgNTkuNjA5IDM5IDU1Ljk3N2MyLjk3Ny00LjA1NSA2LjIzOC03Ljk3NyAxMC4xNC0xMS4xNzIgMi41ODctMS42NTcgNS43NDMtMi4xMTcgOC40MjYtMy42MSA2LjM2OC0zLjE4IDEwLjcxMS05LjAxMSAxNC44Ni0xNC41ODItNS4zMTcgMTMuODA1LTEwLjk5MiAyNy42NjQtMTkuMjk3IDM5Ljk4NXptMCAwIi8%2BPC9zdmc%2B&logoSize=auto&style=flat-square)](https://ch.mathworks.com/matlabcentral/fileexchange/183700-editor-session-commander)[![File Exchange ID](https://img.shields.io/badge/ID%3A-183700-57606A?labelColor=57606A&style=flat-square)](https://ch.mathworks.com/matlabcentral/fileexchange/183700-editor-session-commander)
&emsp;&emsp;
[![Zenodo](https://img.shields.io/badge/-%20-1682D4?logo=zenodo&logoColor=white&logoSize=auto&style=flat-square)](https://doi.org/10.5281/zenodo.19644945)[![Zenodo DOI](https://img.shields.io/badge/DOI%3A-10.5281%2Fzenodo.19644945-57606A?labelColor=57606A&style=flat-square)](https://doi.org/10.5281/zenodo.19644945)

# EditorSessionCommander

![EditorSessionCommander Logo](logo.png)

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
