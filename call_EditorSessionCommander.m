function call_EditorSessionCommander(name, mode, sessionsFolder)
% CALL_EDITORSESSIONCOMMANDER Wrapper for project start-up / shut-down.
%   call_EditorSessionCommander(name, mode, sessionsFolder)
%   name:           session name; prefixed with the OS ('mac-', 'unx-', 'win-')
%   mode:           'save' | 'load' | 'recuperate'
%   sessionsFolder: [] (default, prefdir) or the folder for the sessions
%                   XML. The caller decides; pass an absolute path.
%
% The folder that contains this file must be on the path (it is also
% the folder that contains @EditorSessionCommander).

    if nargin < 3, sessionsFolder = []; end

    % 1. Validate session name and mode
    if ~ischar(name) && ~(isstring(name) && isscalar(name))
        error('The name for an Editor Session must be a character vector or string.');
    end
    mode = lower(char(mode));
    if ~any(strcmp(mode, {'save', 'load', 'recuperate'}))
        error('Unknown mode. Use ''save'', ''load'', or ''recuperate''.');
    end

    % 2. Prefix with the OS (avoids path cross-contamination)
    if ismac
        name = ['mac-' char(name)];
    elseif isunix
        name = ['unx-' char(name)];
    elseif ispc
        name = ['win-' char(name)];
    else
        error('Platform not supported.');
    end

    % 3. Make sure we use the class next to this file, not a stale copy
    here  = fileparts(mfilename('fullpath'));
    found = which('EditorSessionCommander');
    if ~strncmp(found, here, numel(here))
        error('call_EditorSessionCommander:Shadowed', ...
            ['EditorSessionCommander resolves to "%s", not to the copy in "%s". ', ...
             'Run ''which -all EditorSessionCommander'' and remove the stale one.'], found, here);
    end

    % 4. Operation
    switch mode
        case {'save', 'load'}
            % Work from the Project root; return even if session access fails
            origFolder = pwd;
            cleanup_Folder = onCleanup(@() restore_Folder(origFolder)); %#ok<NASGU>
            to_ProjectRoot();
            access_Session(name, mode, sessionsFolder);

        case 'recuperate'
            access_Session(name, 'save', sessionsFolder);   % no Project is open
    end
end

function to_ProjectRoot()
    try
        cd(currentProject().RootFolder);
    catch
        warning('call_EditorSessionCommander:NoProject', ...
            'No active MATLAB Project found. Staying in current folder.');
    end
end

function restore_Folder(folder)
    if exist(folder, 'dir'), cd(folder); end
end

function access_Session(name, mode, sessionsFolder)
    switch mode
        case 'save'
            % Dock Editor so the layout is not empty, save, then close all files
            EditorSessionCommander.dockEditor(true);
            EditorSessionCommander.saveSession(name, false, sessionsFolder);

            allDocs = matlab.desktop.editor.getAll;
            if ~isempty(allDocs)
                allDocs.closeNoPrompt();
            end

        case 'load'
            % 'c' = close current files that are not in the session
            EditorSessionCommander.openSession(name, 'c', sessionsFolder);
            EditorSessionCommander.dockEditor(false);   % personal preference: undock
    end
end