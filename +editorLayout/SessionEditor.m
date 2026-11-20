classdef SessionEditor
    % SessionEditor: backward-compatibility shim for the legacy
    % editorLayout.SessionEditor (File Exchange "EditorSessionManager").
    % Forwards the static API and constants used by old startup.m / finish.m
    % files, shortcuts and wrappers (e.g. call_EditorSessionManager) to
    % EditorSessionCommander. Same XML schema, so both read the same files.
    % The optional last argument (sessionsFolder) is an extension: old code
    % does not pass it and therefore uses prefdir.
    % Do NOT keep the original +editorLayout folder on the path as well.

    properties (Constant = true)
        shortcutOpen = EditorSessionCommander.shortcutOpen;
        shortcutSave = EditorSessionCommander.shortcutSave;
        shortcutCategory = EditorSessionCommander.shortcutCategory;
        shortcutManageSessions = EditorSessionCommander.shortcutManageSessions;
        sessionsXMLshort = EditorSessionCommander.sessionsXMLshort;
    end

    methods (Static = true)
        function openSession(varargin)
            EditorSessionCommander.openSession(varargin{:});
        end
        function saveSession(varargin)
            EditorSessionCommander.saveSession(varargin{:});
        end
        function saveAsSession(name, addSubDirs, folder)
            if nargin < 1, name = []; end
            if nargin < 2, addSubDirs = []; end
            if nargin < 3, folder = []; end
            EditorSessionCommander.saveSession(name, addSubDirs, folder, true);
        end
        function deleteSession(folder)
            if nargin < 1, folder = []; end
            EditorSessionCommander.manageSessions(folder, 'delete');
        end
        function renameSession(folder)
            if nargin < 1, folder = []; end
            EditorSessionCommander.manageSessions(folder, 'rename');
        end
        function viewSession(folder)
            if nargin < 1, folder = []; end
            EditorSessionCommander.manageSessions(folder, 'view');
        end
        function manageSessions(folder)
            if nargin < 1, folder = []; end
            EditorSessionCommander.manageSessions(folder);
        end
    end
end