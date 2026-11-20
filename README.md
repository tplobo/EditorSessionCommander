[![Buy Me a Coffee](https://img.shields.io/badge/-Buy%20Me%20a%20Coffee-FFDD00?logo=buymeacoffee&logoColor=black&logoSize=auto&style=flat-square)](https://buymeacoffee.com/tplobo)[![Buy Me a Coffee user](https://img.shields.io/badge/drinker%3A-tplobo-57606A?labelColor=57606A&style=flat-square)](https://buymeacoffee.com/tplobo)
&emsp;&emsp;
[![File Exchange](https://img.shields.io/badge/-File%20Exchange-D95319?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjggMTI4Ij48cGF0aCBmaWxsPSIjZmZmIiBkPSJNMTIzLjk2NSA5MS45MDJjLTcuMjQ2LTE4LjI5Ny0xMy4yNjItMzcuMDU4LTIwLjE4NC01NS40NzYtMy4wNTQtNy44NC02LjA0Ny0xNS43NDYtMTAuMjE1LTIzLjA4Mi0xLjY1Ni0yLjYzMy0zLjIzOC01LjUyOC01Ljk1My03LjIxNWE0LjAxMyA0LjAxMyAwIDAwLTIuMjIyLS42MDZjLTEuMjcuMDI4LTIuNTM2LjU5NC0zLjUwNCAxLjQxNS0zLjY0NSAyLjg4Ni01LjgwNSA3LjA4Mi04LjIyNyAxMC45NDktNC4yNzcgNy4xNzItOC43ODkgMTQuNjg3LTE1Ljk0MSAxOS4zNDctMy4zNiAyLjM3MS03Ljc2MiAyLjYzLTExIDUuMTcyLTQuNDMgMy4zNC03LjQ0MiA4LjA3OC0xMS4wNzQgMTIuMTg0LS44MjkuOTg4LTIuMTEgMS4zODMtMy4yMjcgMS45MThDMjEuNTc4IDYwLjkzIDEwLjczOCA2NS4zMzYgMCA2OS45OGM5LjA5IDcuMDMyIDE4Ljc3NyAxMy4yOSAyOC4wNSAyMC4wNzkgMi41NDQtLjUwNCA1LjA5OC0xLjU0NyA3LjcyLTEuMDgyIDQuMTYgMS4zIDYuNTk3IDUuMjg1IDguNTAzIDguOTMgMy44NzUgNy45NCA2LjY3NiAxNi4zMjMgOS44MTMgMjQuNTcgNS4yNDYtLjM3NSA5Ljk2OS0zLjA3OSAxNC4wMjctNi4yNTggNy44MDktNi4zMjQgMTMuNzU4LTE0LjUgMjAuMzA1LTIyLjA0NyAzLjE0LTMuMyA2LjM0LTcuMjMgMTEuMDUtOC4xNDkgNC43NjItMS4xNTIgOS44NjQuNTU1IDEzLjM5NSAzLjgzNiA0Ljk1NyA0LjQzIDkuMzQ0IDkuNTUxIDE1LjEzNyAxMi45NDItLjc3Ny0zLjgzNi0yLjY0NS03LjI3OC00LjAzNS0xMC44OTl6TTQyLjk2IDc5LjAxMmMtNC41NyAyLjcwMy05LjQyNiA0LjkzLTE0LjE3NiA3LjI4OS03LjQ1Ny00Ljk5Ni0xNC43MjMtMTAuMjktMjIuMDUtMTUuNDY1IDkuODc4LTQuMzI4IDE5LjkxLTguMzQ4IDI5LjkxNy0xMi4zODcgNC43NDYgMy43MDMgOS42MzcgNy4yMjMgMTQuMzgzIDEwLjkyNi0yLjIzIDMuNTYzLTQuOTE0IDYuODcxLTguMDc0IDkuNjM3em0xMC4xNjgtMTIuNDE0QzQ4LjQxNCA2My4wNTggNDMuNjQgNTkuNjA5IDM5IDU1Ljk3N2MyLjk3Ny00LjA1NSA2LjIzOC03Ljk3NyAxMC4xNC0xMS4xNzIgMi41ODctMS42NTcgNS43NDMtMi4xMTcgOC40MjYtMy42MSA2LjM2OC0zLjE4IDEwLjcxMS05LjAxMSAxNC44Ni0xNC41ODItNS4zMTcgMTMuODA1LTEwLjk5MiAyNy42NjQtMTkuMjk3IDM5Ljk4NXptMCAwIi8%2BPC9zdmc%2B&logoSize=auto&style=flat-square)](https://ch.mathworks.com/matlabcentral/fileexchange/183700-editor-session-commander)[![File Exchange ID](https://img.shields.io/badge/ID%3A-183700-57606A?labelColor=57606A&style=flat-square)](https://ch.mathworks.com/matlabcentral/fileexchange/183700-editor-session-commander)
&emsp;&emsp;
[![Zenodo](https://img.shields.io/badge/-%20-1682D4?logo=zenodo&logoColor=white&logoSize=auto&style=flat-square)](https://doi.org/10.5281/zenodo.19644945)[![Zenodo DOI](https://img.shields.io/badge/DOI%3A-10.5281%2Fzenodo.19644945-57606A?labelColor=57606A&style=flat-square)](https://doi.org/10.5281/zenodo.19644945)


# EditorSessionCommander

![EditorSessionCommander Logo](logo.png)

**EditorSessionCommander** saves and restores MATLAB Editor sessions: which
files are open, in which tile, and how the tiles are arranged. It is the
successor to
[EditorSessionManager](https://ch.mathworks.com/matlabcentral/fileexchange/46352-editor-session-manager),
rebuilt to support the modern Chromium-based desktop while keeping the legacy
Java desktop working and the same session file format.

---

## Key Features

* **Modern UI support:**
Handles the HTML5 layout engine (`DocumentLayout`, `tileCoverage`, row/column weights).
* **Layout fidelity:**
Restores tile grid, spans and proportions. Where the desktop exposes it, it
also restores the order of the tabs in each tile.
* **Hybrid engine:**
Detects the desktop type and uses the matching algorithm.
* **Compatible with EditorSessionManager:**
Same XML schema, and a compatibility package (`+editorLayout`) so existing
`startup.m` / `finish.m` files and shortcuts keep working.
* **Your choice of storage folder:**
Sessions are kept in `prefdir` by default, or in any folder you pass in (for
example a project folder under version control).

---

## Package layout

```text
EditorSessionCommander/
├─ @EditorSessionCommander/       the class: classdef + one file per method
│  └─ private/                    helpers (legacy/modern layout, prompts, trace, ...)
├─ +editorLayout/SessionEditor.m  compatibility shim (see below)
├─ call_EditorSessionCommander.m  wrapper for project start-up / shut-down
├─ install_in_user_path.m         optional installer
└─ create_shortcuts.m             optional shortcut creator (legacy desktop)
```

Put the folder that **contains** `@EditorSessionCommander` on the path
(`addpath`). Never add the `@` or `+` folders themselves, and `genpath` is not
needed.

---

## Usage

### 1. Direct class access
```matlab
EditorSessionCommander.saveSession('MyProject');
EditorSessionCommander.openSession('MyProject');
EditorSessionCommander.manageSessions();          % interactive menu
```
All entry points take an optional last argument `sessionsFolder`, see below.

### 2. Wrapper for projects (recommended)
```matlab
% in the project start-up script
call_EditorSessionCommander('MyProject', 'load', sessionsFolder);
% in the project shut-down script
call_EditorSessionCommander('MyProject', 'save', sessionsFolder);
% when MATLAB crashed and no project is open: save the current Editor state
call_EditorSessionCommander('MyProject', 'recuperate', sessionsFolder);
```
- The session name is prefixed with the platform (`mac-`, `unx-`, `win-`), so
  one shared XML can hold one session per operating system.
- `load` and `save` run from the root folder of the current MATLAB Project
  and return to the original folder afterwards, even on failure.
- `save` docks the Editor, saves the session and closes all files. `load`
  restores the session and then undocks the Editor.
- The wrapper stops with an error if `EditorSessionCommander` resolves to a
  different copy than the one next to it. Run
  `which -all EditorSessionCommander` to find the stale copy.

### 3. Where the sessions are stored: `sessionsFolder`
`sessionsFolder` is the last argument of every entry point and of the class
constructor:
- `[]` or `''` (default): MATLAB's `prefdir`. Sessions are then shared by all
  releases that use that preferences folder.
- A path (absolute, or relative to the current folder, `~` allowed): the
  folder is created if needed and `savedEditorSessions.xml` lives there.

The package never chooses a location by itself. A project decides, for example:
```matlab
esc_folder = fullfile(pwd, 'PROJECT', 'project_preferences');
call_EditorSessionCommander('MIRA', 'load', esc_folder);
```
This replaces the earlier approach of overloading `prefdir`.

---

## Compatibility with EditorSessionManager (`+editorLayout`)

The old package was called `editorLayout.SessionEditor`, and startup files,
shortcut callbacks and wrappers such as `call_EditorSessionManager` use that
name. The `+editorLayout` folder contains a thin shim with the same static
API (`openSession`, `saveSession`, `saveAsSession`, `deleteSession`,
`renameSession`, `viewSession`, `manageSessions`) and the same shortcut
constants. It forwards everything to `EditorSessionCommander`.

```matlab
editorLayout.SessionEditor.openSession(pwd, 'c');   % still works
editorLayout.SessionEditor.saveSession(pwd, false);
```

- Both packages read and write the same XML, so existing sessions load.
- The shim covers the static API only, not instance calls such as
  `editorLayout.SessionEditor()`.
- Without a folder argument, the shim uses `prefdir`, like the old package.
- **Do not keep the original `+editorLayout` folder on the path** at the same
  time, since MATLAB would pick one of the two arbitrarily.
- If you don't use old startup files, shortcuts or wrappers, you can delete
  `+editorLayout`.

---

## Compatibility & requirements

| Release range | Desktop engine | Status |
| :--- | :--- | :--- |
| **<= R2021a**       | Classic Desktop    | **Supported** (legacy algorithm) |
| **R2021b - R2022b** | Classic Desktop    | **Unsupported** (future work)    |
| **R2023a - R2024b** | Classic Desktop    | **Unsupported** (future work)    |
| **R2023a - R2024b** | New Desktop (Beta) | **Supported** (modern algorithm) |
| **>= R2025a**       | New Desktop        | **Supported** (modern algorithm) |

> In R2023a-R2024b the New Desktop (Beta) must be active to use the modern
> algorithm.

The author has tested the legacy algorithm on R2021a and the modern one on
R2026a, on macOS. Other releases and platforms are untested.

---

## How it works

**Modern desktop.** Files that are not part of the session are closed. The
grid, the tile coverage and the tile occupancy are written to the desktop's
`DocumentLayout`. It is applied twice, because the first pass creates the
grid and the second one places the tabs. The modern path always closes
files that are not in the session.

**Legacy desktop.** Java does not say which tile is which, so the class
resets the Editor to a single tile, rebuilds the grid, and opens one small
marker file per tile. It reads the markers' screen positions to correlate the
saved tiles with the real ones, moves the session files, and closes the
markers.
- Markers live in a private folder inside `tempdir`, never in your project.
- Marker tabs and their folder are removed even if loading fails, and folders
  left by a crash are swept after a day.
- Markers are never stored in a session. Old marker entries (`tileN.m` from
  the original package) are removed when a session loads.

---

## Layout limitations: legacy vs. modern
The legacy Java Editor allowed free-form tiling in which adjacent tiles have
independent boundaries. The modern HTML5 Editor uses a strict grid.

### Legacy (flexible)
```text
+-----------------------+
|        Tile 1         |
+-------------+---------+
|    Tile 2   |  Tile 3 |
+---------+---+---------+
| Tile 4  |    Tile 5   |
+---------+-------------+
```
### Modern (strict grid)
```text
+-----------+-----------+
|        Tile 1         |
+-----------+-----------+
|  Tile 2   |  Tile 3   |
+-----------+-----------+
|  Tile 4   |  Tile 5   |
+-----------+-----------+
```
When a legacy layout is loaded on the modern desktop, it is fitted to the
closest grid.

Modern layouts are stored as proportions scaled to 10000 ("pseudo-pixels"),
with rounded cumulative edges, so a session saved on the modern desktop can
be loaded on the legacy one.

---

## Known limitations

- **Tab order:** the modern desktop saves and restores the order of tabs in
  each tile. The legacy desktop cannot report it: it only lists files in the
  order they were opened, so a legacy save records that order. Files then
  open in the stored order, so a session saved on the modern desktop
  restores its tab order on the legacy desktop, but not the other way round.
- **Unsaved documents:** an unsaved "untitled" buffer open at save time is
  stored as a file entry. On load you are asked whether to remove it.
- **Interactive prompts:** if a file in a session has moved or is missing,
  loading asks what to do in the Command Window.
- **Docking uses keyboard shortcuts** (`Ctrl+Shift+D` / `Ctrl+Shift+U`)
  sent through `java.awt.Robot`, so it needs a display and may take a moment.
- **R2021b-R2024b with the classic desktop** are not supported.

---

## Troubleshooting

**Debug trace.** Run `setenv('ESC_DEBUG', '1')` before loading a session. The
legacy path prints the grid size at each step, marker placement and
correlation. The modern path prints the documents closed and the layout
applied. Include this output in bug reports.

**Stale copies.** "Too many input arguments" or other unexpected errors after
an update usually mean an older copy of the class is first on the path. Run
`which -all EditorSessionCommander`, delete older copies (a single-file
`EditorSessionCommander.m` in `userpath`, for instance) and restart MATLAB.

**Legacy grid collapses.** The Java desktop can drop an empty tile and
collapse the grid. The class rebuilds the grid from a clean single tile and
retries up to three times. If it still fails, it stops with an error that
states the grid it found.

---

## Installation

* **Project use (recommended):** keep the package folder in your project,
  `addpath` it before calling `call_EditorSessionCommander` and `rmpath` it
  afterwards.
* **User path:** run `install_in_user_path.m` to copy the class folder, the
  `+editorLayout` package and the wrapper to `userpath`, so they are available
  at MATLAB start (for a `startup.m` or shortcuts). A copy in `userpath` can
  shadow the one in your project, so remove it when you stop using it.
* **Shortcuts:** run `create_shortcuts.m`. On the legacy desktop it adds
  "Save", "Load" and "Manage" shortcuts. On the modern desktop it prints the
  labels and commands to add to your Favorites by hand.
