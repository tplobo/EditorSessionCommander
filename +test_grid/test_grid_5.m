%% Setup paths for 5 files
base = pwd;
targetFiles = {fullfile(base,'T1_Top.m'), ...
    fullfile(base,'T2_MidLeft.m'), ...
    fullfile(base,'T2_MidRight.m'), ...
    fullfile(base,'T3_Bottom.m'), ...
    fullfile(base,'T4_Extra.m')};

%% 1. Ensure files exist and are open
for i = 1:numel(targetFiles)
    if ~exist(targetFiles{i}, 'file'), writelines("%% File "+i, targetFiles{i}); end
    edit(targetFiles{i}); 
end
pause(0.5);
drawnow;

%% 2. Cleanup: Close everything EXCEPT target files
allDocs = matlab.desktop.editor.getAll;
for i = 1:numel(allDocs)
    if ~any(strcmp(allDocs(i).Filename, targetFiles))
        allDocs(i).closeNoPrompt();
    end
end
drawnow;

%% 3. Define a Complex Grid
% We want a 3-row, 2-column grid:
% [ 1  1 ]  <- Tile 1 (Top spans both cols)
% [ 2  3 ]  <- Tile 2 and 3 (Middle split)
% [ 4  4 ]  <- Tile 4 (Bottom spans both cols)

L = struct();
L.gridDimensions.w = 2;
L.gridDimensions.h = 3;
L.tileCount = 4;
L.tileCoverage = [1, 1; ...
    2, 3; ...
    4, 4];

L.columnWeights = [0.5, 0.5];
L.rowWeights    = [0.33, 0.33, 0.34];

% 4. Build Occupancy (Mapping 5 files into 4 tiles)
% Tile 1: T1_Top.m
% Tile 2: T2_MidLeft.m
% Tile 3: T2_MidRight.m
% Tile 4: T3_Bottom.m AND T4_Extra.m (Stacked tabs)

occ(1).children = struct('id', "editorFile_" + targetFiles{1});
occ(2).children = struct('id', "editorFile_" + targetFiles{2});
occ(3).children = struct('id', "editorFile_" + targetFiles{3});
% Note: Tile 4 gets TWO files as a struct array
occ(4).children = [struct('id', "editorFile_" + targetFiles{4}), ...
    struct('id', "editorFile_" + targetFiles{5})];

L.tileOccupancy = occ;

%% 5. The Double-Tap Application
app = matlab.ui.container.internal.RootApp.getInstance();

fprintf('Executing Double-Tap on Complex Layout...\n');

% Pass 1
app.DocumentLayout = L;
drawnow;
pause(0.6); % Slightly longer pause for complex layouts

% Pass 2
app.DocumentLayout = L;
drawnow;

fprintf('Stress test complete. Layout should be Top(1), Mid(2|3), Bottom(2 files).\n');