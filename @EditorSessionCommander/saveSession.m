function saveSession(sessionName, addSubDirectoriesToPath, sessionsFolder, forceNew)
% SAVESESSION Saves the current editor state. Overwrites the session with
% the same name or index, otherwise creates a new one.
%   saveSession(name, addSubDirs, sessionsFolder, forceNew)
%   []   for name / addSubDirs -> ask interactively (addSubDirs keeps the
%        stored value when overwriting).
%   forceNew (default false): always append a new session, even if the name
%        already exists (the old "saveAsSession").

    if nargin < 1, sessionName = []; end
    if nargin < 2, addSubDirectoriesToPath = []; end
    if nargin < 3, sessionsFolder = []; end
    if nargin < 4 || isempty(forceNew), forceNew = false; end

    obj = EditorSessionCommander(sessionsFolder);
    [T, sessions] = obj.getSessions();

    if isempty(sessionName)
        if forceNew || height(T) == 0
            sessionName = input('Type a name for the new session: ', 's');
        else
            fprintf('\nExisting session files:\n');
            disp(T);
            sessionName = input('Choose a session to overwrite (Name or Index) or type a new name: ', 's');
        end
        if isempty(sessionName)
            fprintf('Warning: Save cancelled. No name provided.\n');
            return;
        end
    end
    sessionName = char(sessionName);

    % Match by name, or by index
    matchnum = 0;
    if ~forceNew
        nameMatch = find(strcmp(sessionName, T.name), 1, 'last');
        if ~isempty(nameMatch)
            matchnum = nameMatch;
        else
            idxMatch = str2double(sessionName);
            if ~isnan(idxMatch) && any(idxMatch == T.index)
                matchnum = idxMatch;
                sessionName = T.name{matchnum};
            end
        end
    end

    if matchnum ~= 0
        disp(['Overwriting existing session: ', sessionName]);
        if isempty(addSubDirectoriesToPath)
            addSubDirectoriesToPath = strcmpi(T.addPaths{matchnum}, 'true');
        end
        obj.editNode('delete', sessions.item(matchnum - 1));
    else
        disp(['Saving as new session: ', sessionName]);
        if isempty(addSubDirectoriesToPath)
            resp = askChar('Include sub-directories in path when loaded (y/n)? ', 'yntf');
            addSubDirectoriesToPath = any(resp == 'yt');
        end
    end

    obj.appendSession(sessionName, logical(addSubDirectoriesToPath));
    obj.save();
    fprintf('Session "%s" saved successfully.\n', sessionName);
end