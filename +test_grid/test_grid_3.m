%% Setup paths
f1 = fullfile(pwd, 'test_file_A.m');
f2 = fullfile(pwd, 'test_file_B.m');
f3 = fullfile(pwd, 'test_file_C.m');
targetFiles = {f1, f2, f3};

%% 1. Ensure files are open and the Editor is Docked
for i = 1:numel(targetFiles)
    edit(targetFiles{i}); 
end

% CRITICAL: The Editor MUST be docked for DocumentLayout to work
% EditorManager.dockEditor(); 

pause(0.5);
drawnow;

%% 2. Cleanup: Close everything EXCEPT target files
% This prevents "Ghost" files from confusing the layout engine
allDocs = matlab.desktop.editor.getAll;
for i = 1:numel(allDocs)
    if ~any(strcmp(allDocs(i).Filename, targetFiles))
        allDocs(i).closeNoPrompt();
    end
end
drawnow;

%% 3. Apply Layout Twice (The Workaround)
app = matlab.ui.container.internal.RootApp.getInstance();

% Build the layout structure once
L = buildLayoutStruct(targetFiles);

fprintf('Attempting Layout Application...\n');

% First Pass: Resets the engine and attempts placement
app.DocumentLayout = L;
drawnow;
pause(0.5); % Give the HTML layer time to "catch up"

% Second Pass: Solidifies placement now that tabs exist in the DOM
app.DocumentLayout = L;
drawnow;

fprintf('Layout [1,1;2,3] applied (Double-tap complete).\n');


%% --- Helper Function ---
function L = buildLayoutStruct(filePaths)
    L = struct();
    L.gridDimensions = struct('w', 2, 'h', 2);
    L.tileCount = 3;
    L.tileCoverage = [1, 1; 2, 3];
    L.columnWeights = [0.5, 0.5];
    L.rowWeights    = [0.5, 0.5];

    % Mapping files to tiles based on naming
    % Tile 1: File A, Tile 2: File B, Tile 3: File C
    for i = 1:numel(filePaths)
        [~, name] = fileparts(filePaths{i});
        idStr = "editorFile_" + filePaths{i};
        
        child = struct('id', idStr);
        
        if contains(name, '_A')
            occ(1).children = child;
        elseif contains(name, '_B')
            occ(2).children = child;
        elseif contains(name, '_C')
            occ(3).children = child;
        end
    end
    L.tileOccupancy = occ;
end