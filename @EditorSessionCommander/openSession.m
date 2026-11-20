function openSession(NameIn, TreatmentOfOpenFiles, sessionsFolder)
% OPENSESSION Restores a saved editor state.
%   NameIn:               session name ([] or omitted -> interactive choice).
%   TreatmentOfOpenFiles: 'c' (default) closes open files that are not part
%                         of the session; any other value keeps them
%                         (modern desktop: they are always closed).
%   sessionsFolder:       [] (prefdir) or a folder path.

    if nargin < 1, NameIn = []; end
    if nargin < 2 || isempty(TreatmentOfOpenFiles), TreatmentOfOpenFiles = 'c'; end
    if nargin < 3, sessionsFolder = []; end

    obj = EditorSessionCommander(sessionsFolder);
    [T, sessions, files] = obj.getSessions();
    if height(T) == 0
        fprintf('No saved sessions in %s\n', obj.xmlFileName);
        return
    end

    % --- Session selection and environment ------------------------------ %
    indexFound = [];
    if ~isempty(NameIn)
        indexFound = find(strcmp(T.name, char(NameIn)), 1, 'last');
        if isempty(indexFound)
            disp(['Session name "', char(NameIn), '" not recognized.']);
        end
    end
    if isempty(indexFound)
        indexFound = chooseOption(T);
        while numel(indexFound) > 1
            disp('Please only choose one option.');
            indexFound = chooseOption(T);
        end
        if isempty(indexFound), return; end
    end

    sessionNode = sessions.item(indexFound - 1);
    sessionNode.setAttribute(obj.sessionLastUsed, datestr(now));
    obj.save();

    try
        targetDir = T.currentFolder{indexFound};
        if exist(targetDir, 'dir')
            cd(targetDir);
        else
            warning('EditorSessionCommander:FolderNotFound', 'Saved folder not found: %s', targetDir);
        end
    catch ME
        fprintf(2, 'Could not change directory: %s\n', ME.message);
    end

    if strcmpi(T.addPaths{indexFound}, 'true')
        addpath(genpath(pwd));
    end

    % --- Layout requirements -------------------------------------------- %
    numFilesCount = T.numFiles{indexFound};
    tiles = zeros(numFilesCount, 1);
    for i = 1:numFilesCount
        tileAttr = char(files{indexFound}.item(i-1).getAttribute(obj.fileTile));
        if ~isempty(tileAttr), tiles(i) = str2double(tileAttr); end
    end
    numTilesNeeded = max([tiles; -1]) + 1;      % number of docked tiles

    [layoutNode, layoutWH, tileTable] = obj.getLayout(sessionNode);
    if isempty(layoutNode)
        error('Session saved in improper XML format: no layout info');
    end

    % Legacy only: re-create the tile grid (with marker files) BEFORE opening
    % files. 'legacy' must stay alive until the end: it owns the marker cleanup.
    legacy = [];
    if ~obj.isNewUI
        legacy = legacyLayout('prepare', layoutWH, tileTable, numTilesNeeded, numTilesNeeded == 2);
    end

    % --- File reconciliation and opening -------------------------------- %
    editorOpenFileNames = getOpenEditorFiles(obj.isNewUI);

    nodes = cell(1, numFilesCount);   % static copy: nodes may be deleted below
    for i = 1:numFilesCount
        nodes{i} = files{indexFound}.item(i-1);
    end
    [sessionTileStatus, tileFileCorrelation, editorFileStatus] = ...
        reconcileSessionFiles(obj, nodes, editorOpenFileNames);

    % Marker tabs are never "foreign" files
    if ~isempty(editorOpenFileNames)
        editorFileStatus = editorFileStatus | cellfun(@isMarkerFile, editorOpenFileNames);
    end

    % --- Final layout ---------------------------------------------------- %
    if obj.isNewUI
        modernLayout(obj, tileTable, tiles, sessionTileStatus, tileFileCorrelation);
    else
        legacyLayout('finish', legacy, tileTable, tiles, sessionTileStatus, ...
            tileFileCorrelation, editorFileStatus, editorOpenFileNames, TreatmentOfOpenFiles);
    end

    obj.save();
end

% ===== local helpers ================================================ %

function [tileStatus, tileFile, editorKept] = reconcileSessionFiles(obj, nodes, openNames)
% Matches session files against open files / disk / path, opens what is
% needed and returns, per session file, whether it must be moved to its tile
% (tileStatus), the identifier to use for that (tileFile), and which of the
% currently open files belong to the session (editorKept).
%   Match cases: 1 open (same path) | 2 on disk | 3 open (other folder)
%                4 elsewhere on path | -1 not found
    n = numel(nodes);
    shortNames = cellfun(@shortName, openNames, 'UniformOutput', false);
    tileStatus = false(n, 1);
    tileFile = cell(n, 1);
    editorKept = false(size(openNames));

    for i = 1:n
        node = nodes{i};
        p = char(node.getAttribute(obj.fileName));
        sn = shortName(p);

        if isMarkerFile(p)              % self-heal sessions polluted by marker files
            obj.editNode('file', node, []);
            continue
        end

        if any(strcmp(p, openNames)),           matchCase = 1;
        elseif exist(p, 'file'),                matchCase = 2;
        elseif any(strcmp(sn, shortNames)),     matchCase = 3;
        elseif ~isempty(which(sn)),             matchCase = 4;
        else,                                   matchCase = -1;
        end

        switch matchCase
            case -1
                fprintf(2, 'Warning: File "%s" not found.\n', p);
                resp = input('Remove from session [y/n]? ', 's');
                if strcmpi(resp, 'y'), obj.editNode('file', node, []); end

            case 1
                editorKept = editorKept | strcmp(p, openNames);
                tileStatus(i) = true;  tileFile{i} = p;

            case 2
                matlab.desktop.editor.openDocument(p);
                tileStatus(i) = true;  tileFile{i} = p;

            case 3
                possible = strcmp(sn, shortNames);
                fprintf('Warning: "%s" is open from a different location.\n', sn);
                resp = input('[1] Leave open, [2] Update session path, [3] Close/Remove, [Any] Skip: ', 's');
                switch resp
                    case '1'
                        editorKept = editorKept | possible;
                        tileStatus(i) = true;  tileFile{i} = openNames{find(possible, 1)};
                    case '2'
                        editorKept = editorKept | possible;
                        matched = openNames(possible);
                        obj.editNode('file', node, matched);
                        tileStatus(i) = true;  tileFile{i} = matched{1};
                    case '3'
                        obj.editNode('file', node, []);
                end

            case 4
                resolved = which(sn);
                fprintf('Warning: "%s" found at: %s\n', sn, resolved);
                resp = input('[1] Open & Update Session, [2] Remove from Session, [3] Open (Keep XML path): ', 's');
                switch resp
                    case '1'
                        matlab.desktop.editor.openDocument(resolved);
                        obj.editNode('file', node, resolved);
                        tileStatus(i) = true;  tileFile{i} = resolved;
                    case '2'
                        obj.editNode('file', node, []);
                    case '3'
                        matlab.desktop.editor.openDocument(resolved);
                        tileStatus(i) = true;  tileFile{i} = resolved;
                end
        end
    end
end

function s = shortName(p)
    [~, n, e] = fileparts(p);
    s = [n e];
end