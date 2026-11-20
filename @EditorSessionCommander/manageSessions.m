function manageSessions(sessionsFolder, action)
% MANAGESESSIONS Interactive session management.
%   manageSessions(sessionsFolder)           menu: save/open/rename/view/delete
%   manageSessions(sessionsFolder, action)   action: 'delete' | 'rename' | 'view'
    if nargin < 1, sessionsFolder = []; end
    if nargin < 2, action = ''; end

    switch lower(action)
        case '',       runMenu(sessionsFolder);
        case 'delete', deleteSessions(sessionsFolder);
        case 'rename', renameSession(sessionsFolder);
        case 'view',   viewSession(sessionsFolder);
        otherwise
            error('EditorSessionCommander:BadAction', 'Unknown action "%s".', action);
    end
end

function runMenu(sessionsFolder)
    choices = 'sorvde';
    descriptions = {'Save session'; 'Open session'; 'Rename session'; ...
        'View session files and details'; 'Delete session'; 'Exit'};
    callbacks = { ...
        @() EditorSessionCommander.saveSession([], [], sessionsFolder);
        @() EditorSessionCommander.openSession([], 'c', sessionsFolder);
        @() renameSession(sessionsFolder);
        @() viewSession(sessionsFolder);
        @() deleteSessions(sessionsFolder);
        @() []};

    response = '';
    while ~strcmpi(response, 'e')
        response = askChar('What would you like to do? ', choices, @() showMenu(choices, descriptions));
        callbacks{find(response == choices, 1)}();
    end
end

function showMenu(choices, descriptions)
    fprintf('\n=== Editor Session Commander ===\n');
    for i = 1:length(choices)
        fprintf(' [%s] %s\n', choices(i), descriptions{i});
    end
end

function deleteSessions(sessionsFolder)
    obj = EditorSessionCommander(sessionsFolder);
    [T, sessions] = obj.getSessions();
    if height(T) == 0
        disp('No sessions available to delete.');
        return;
    end

    indexFound = chooseOption(T);
    if isempty(indexFound), return; end

    fprintf('\nSelected for deletion:\n');
    disp(T(indexFound, :));
    response = input('Delete session(s)? [y/n]: ', 's');

    if ~isempty(response) && strcmpi(response(1), 'y')
        % Collect nodes first to avoid index shifts during deletion
        toDelete = cell(1, numel(indexFound));
        for i = 1:numel(indexFound)
            toDelete{i} = sessions.item(indexFound(i) - 1);
        end
        for i = 1:numel(toDelete)
            obj.editNode('delete', toDelete{i});
        end
        fprintf('Successfully deleted %d session(s).\n', numel(indexFound));
    else
        disp('Deletion cancelled.');
    end
end

function renameSession(sessionsFolder)
    obj = EditorSessionCommander(sessionsFolder);
    [T, sessions] = obj.getSessions();
    if height(T) == 0
        disp('No sessions available to rename.');
        return;
    end

    indexFound = chooseOption(T);
    while numel(indexFound) > 1
        disp('Please only choose one option at a time for renaming.');
        indexFound = chooseOption(T);
    end
    if isempty(indexFound), return; end

    fprintf('\nRenaming session:\n');
    disp(T(indexFound, :));

    newName = input('Enter the new name (or press Enter to cancel): ', 's');
    if isempty(newName)
        disp('Rename cancelled.');
        return;
    end

    obj.editNode('rename', sessions.item(indexFound - 1), newName);
    fprintf('Session renamed to "%s".\n', newName);
end

function viewSession(sessionsFolder)
    obj = EditorSessionCommander(sessionsFolder);
    [T, sessions, files] = obj.getSessions();
    if height(T) == 0
        disp('No sessions available to view.');
        return;
    end

    indexFound = chooseOption(T);
    while numel(indexFound) > 1
        disp('Please only choose one option.');
        indexFound = chooseOption(T);
    end
    if isempty(indexFound), return; end

    fprintf('\n--- Session Overview ---\n');
    disp(T(indexFound, :));

    fprintf('Files in this session:\n');
    for i = 1:T.numFiles{indexFound}
        fileNode = files{indexFound}.item(i-1);
        fullPath = char(fileNode.getAttribute(obj.fileName));
        tileAttr = char(fileNode.getAttribute(obj.fileTile));

        if isempty(tileAttr)
            fprintf('  [?]: %s\n', fullPath);
        else
            tileNum = str2double(tileAttr);
            if tileNum <= -1
                fprintf('  F%d: %s\n', abs(tileNum), fullPath);   % floating window
            else
                fprintf('  T%d: %s\n', tileNum, fullPath);        % docked tile
            end
        end
    end

    [~, layoutWH, tileTable] = obj.getLayout(sessions.item(indexFound - 1));

    fprintf('\nGrid Dimensions (Cols x Rows):\n');
    if ~isempty(layoutWH)
        fprintf('  %d x %d\n', layoutWH(1), layoutWH(2));
    else
        disp('  No layout dimensions specified.');
    end
    if ~isempty(tileTable)
        fprintf('Tile Geometry Table:\n');
        disp(tileTable);
    end
end