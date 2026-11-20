classdef EditorSessionCommander < handle
    % EditorSessionCommander: Controls Editor sessions for both Java and
    % HTML versions. Sessions live in 'savedEditorSessions.xml' (same schema
    % as the legacy editorLayout.SessionEditor).
    %
    % sessionsFolder (last argument of the constructor and of the static
    % entry points): [] or '' -> MATLAB's prefdir; otherwise an absolute or
    % pwd-relative folder (created if missing).

    properties
        xmlDocument
        xmlFileName
        hApp
        isNewUI
    end

    properties (Constant = true)
        shortcutOpen = 'Load Editor Session';
        shortcutSave = 'Save Editor Session';
        shortcutCategory = 'Editor Sessions';
        shortcutManageSessions = 'Manage Sessions';

        sessionsXMLshort = 'savedEditorSessions.xml';

        rootElement = 'SavedEditorSessions';

        sessionNode = 'Session';
        sessionName = 'name';
        sessionCurrentFolder = 'currentFolder';
        sessionPathRecursiveAdd = 'recursivePath';
        sessionLastUsed = 'lastLoaded';
        sessionLastSaved = 'lastSaved';

        sessionLayoutNode = 'Layout';
        sessionTileNode = 'Tile';
        sessionFileNode = 'File';

        dispScale   = 10000;        % Scaling for modern displays
        tileH = 'h';
        tileW = 'w';
        tileX = 'x';
        tileY = 'y';

        fileName = 'name';
        fileTile = 'tile';
        fileSelectionOrder = 'order';
    end

    properties (Constant, Hidden)
        % Get release string (e.g., 'R2026a').
        REL = subsref(matlabRelease, substruct('.', 'Release'))

        % ERA 1: <= R2021a (LEGACY path)
        IS_LEGACY = (EditorSessionCommander.REL <= "R2021a")

        % ERA 2: The "Dead Zone" (R2021b - R2022b, requires patch)
        IS_DEAD   = (EditorSessionCommander.REL >= "R2021b" && EditorSessionCommander.REL <= "R2022b")

        % ERA 3: The Transition (R2023a - R2024b, works on New Desktop)
        IS_TRANS  = (EditorSessionCommander.REL >= "R2023a" && EditorSessionCommander.REL <= "R2024b")

        % ERA 4: >= R2025a+ (MODERN path)
        IS_MODERN = (EditorSessionCommander.REL >= "R2025a")
    end

    methods

        function obj = EditorSessionCommander(sessionsFolder)
            % Constructor: load/create the sessions XML and hook into the UI engine.
            % sessionsFolder: [] / '' (prefdir) or a folder path.

            if nargin < 1, sessionsFolder = []; end

            % XML Initialization
            obj.xmlFileName = fullfile(resolveSessionsFolder(sessionsFolder), obj.sessionsXMLshort);
            if exist(obj.xmlFileName, 'file')
                try
                    obj.xmlDocument = xmlread(obj.xmlFileName);
                    root = obj.xmlDocument.getDocumentElement;
                    root.normalize();
                    removeSpace(root);
                catch e
                    error('Could not read file %s: %s', obj.xmlFileName, e.message);
                end
            else
                obj.xmlDocument = com.mathworks.xml.XMLUtils.createDocument(obj.rootElement);
            end

            % Hook into UI engine
            [isNewUI, app] = obj.isNewDesktop();
            if isNewUI
                obj.dockEditor(true);   % Dock the Editor if it is currently floating
                app = matlab.ui.container.internal.RootApp.getInstance();
            end
            obj.hApp = app;
            obj.isNewUI = isNewUI;

            % Issue Warnings/Errors based on Eras
            if obj.IS_DEAD
                warning('ESC:DeadZone', ...
                    'R2021b-R2022b are currently unsupported. Layout restoration may fail.');
            elseif obj.IS_TRANS && ~isNewUI
                warning('ESC:NewDesktopRequired', ...
                    ['You are in R2023a-R2024b but the New Desktop (Beta) is not active. ', ...
                    'Please switch to the New Desktop to use Modern features.']);
            end
        end

        function obj = save(obj)
            % SAVE Writes the current xmlDocument memory to the xmlFileName on disk.
            try
                xmlwrite(obj.xmlFileName, obj.xmlDocument);
            catch e
                fprintf(2, 'Failed to write session file: %s\n', e.message);
                for i = 1:length(e.stack)
                    disp(e.stack(i));
                end
                error('EditorSessionCommander:SaveFailed', ...
                    'Could not write to file: %s', obj.xmlFileName);
            end
        end

        obj = appendSession(obj, sessionName, addSubDirectoriesToPath)
        editNode(obj, action, node, value)
        [T, sessions, files] = getSessions(obj)
        [layoutNode, layoutWH, tileTable] = getLayout(obj, session)

    end

    methods (Static = true)

        [tf, app] = isNewDesktop()
        dockEditor(docked)
        openSession(NameIn, TreatmentOfOpenFiles, sessionsFolder)
        saveSession(sessionName, addSubDirectoriesToPath, sessionsFolder, forceNew)
        manageSessions(sessionsFolder, action)

    end

end

% ===== local helpers (constructor only) ============================= %

function folder = resolveSessionsFolder(folder)
% RESOLVESESSIONSFOLDER Absolute, existing folder holding the sessions XML.
%   [] or '' -> prefdir. Anything else is a path (absolute, or relative to
%   pwd; '~' is expanded) and is created if missing. There is deliberately
%   no keyword: a local folder called "prefdir" is just a folder.
    if isempty(folder)
        folder = prefdir;
        return
    end
    if ~(ischar(folder) || (isstring(folder) && isscalar(folder)))
        error('EditorSessionCommander:BadFolder', ...
            'sessionsFolder must be [], a character vector or a string scalar.');
    end
    folder = char(folder);
    if strncmp(folder, '~', 1)
        folder = [char(java.lang.System.getProperty('user.home')) folder(2:end)];
    end
    if isempty(regexp(folder, '^([A-Za-z]:[\\/]|[\\/])', 'once'))
        folder = fullfile(pwd, folder);
    end
    if ~exist(folder, 'dir')
        [ok, msg] = mkdir(folder);
        if ~ok
            error('EditorSessionCommander:FolderFailed', 'Could not create "%s": %s', folder, msg);
        end
    end
    end

    function removeSpace(node)
    % REMOVESPACE Recursively strips whitespace text nodes (avoids new-line
    % build-up in the XML at every save).
    children = node.getChildNodes;
    for childi = children.getLength:-1:1
        child = children.item(childi-1);
        if child.getNodeType == 3
            node.removeChild(child);
        elseif child.hasChildNodes
            removeSpace(child);
        end
    end
end
