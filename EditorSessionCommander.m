classdef EditorSessionCommander < handle
    % EditorSessionCommander: Controls Editor sessions for both Java and
    % HTML versions.

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
        % Get release string (e.g., 'R2026a'). Default to old if command missing.
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

        function obj = EditorSessionCommander()
            % Constructor: Initialize XML and ensure Editor is Docked for R2026a
            
            % XML Initialization
            obj.xmlFileName = fullfile(prefdir, obj.sessionsXMLshort);
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
                % Dock the Editor if it is currently floating
                obj.dockEditor(); 

                % Refresh app instance after docking to ensure sync
                app = matlab.ui.container.internal.RootApp.getInstance();
            end
            obj.hApp = app;
            obj.isNewUI = isNewUI;

            % Issue Warnings/Errors based on Eras
            if obj.IS_DEAD
                warning('ESC:DeadZone',                                     ...
                    'R2021b-R2022b are currently unsupported. Layout restoration may fail.');

            elseif obj.IS_TRANS && ~isNewUI
                warning('ESC:NewDesktopRequired', ...
                    ['You are in R2023a-R2024b but the New Desktop (Beta) is not active. ', ...
                    'Please switch to the New Desktop to use Modern features.']);
            end
            
            % Helper to clean XML
            function removeSpace(node)
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
        end

        function obj = save(obj)
            % SAVE Writes the current xmlDocument memory to the xmlFileName on disk.
            try
                % Write the XML structure to the file
                xmlwrite(obj.xmlFileName, obj.xmlDocument);
            catch e
                % Log the error details for debugging
                fprintf(2, 'Failed to write session file: %s\n', e.message);
                for i = 1:length(e.stack)
                    disp(e.stack(i));
                end
                error('EditorSessionCommander:SaveFailed', 'Could not write to file: %s', obj.xmlFileName);
            end
        end

        function obj = appendSession(obj, sessionName, addSubDirectoriesToPath)
            if nargin < 2, sessionName = []; end
            if nargin < 3, addSubDirectoriesToPath = false; end

            % Convert bool to string for XML storage
            if addSubDirectoriesToPath; recurseStr = 'true'; else, recurseStr = 'false'; end

            % Create the high-level Session Node
            newSessionNode = obj.xmlDocument.createElement(obj.sessionNode);
            newSessionNode.setAttribute(obj.sessionName, sessionName);
            newSessionNode.setAttribute(obj.sessionCurrentFolder, pwd);
            newSessionNode.setAttribute(obj.sessionPathRecursiveAdd, recurseStr);
            dateTime = datestr(now);
            newSessionNode.setAttribute(obj.sessionLastUsed, dateTime);
            newSessionNode.setAttribute(obj.sessionLastSaved, dateTime);

            root = obj.xmlDocument.getDocumentElement;
            root.appendChild(newSessionNode);

            newLayoutNode = obj.xmlDocument.createElement(obj.sessionLayoutNode);
            newSessionNode.appendChild(newLayoutNode);
            
            if obj.isNewUI
                % --- MODERN HTML PATH --- %
                layout = obj.hApp.DocumentLayout;

                % Set Grid Dimensions on the Layout node
                newLayoutNode.setAttribute(obj.tileW, num2str(layout.gridDimensions.w));
                newLayoutNode.setAttribute(obj.tileH, num2str(layout.gridDimensions.h));
                
                tc = layout.tileCoverage;
                colW = layout.columnWeights; 
                rowW = layout.rowWeights;

                % Iterate through Tiles defined in the modern Layout
                for t = 1:numel(layout.tileOccupancy)

                    % Find grid cells covered by this tile to calculate proportions
                    [rows, cols] = find(tc == t);
                    if isempty(rows), continue; end
                    
                    % Calculate Pseudo-Pixels (Proportions * 10000)
                    % This ensures legacy compatibility and cross-resolution stability.
                    % pW/pH: Sum of weights for the columns/rows this tile spans.
                    % pX/pY: Sum of weights for all columns/rows to the left/top of this tile.
                    pW = sum(colW(min(cols):max(cols))) * 10000;
                    pH = sum(rowW(min(rows):max(rows))) * 10000;
                    pX = sum(colW(1:(min(cols)-1))) * 10000;
                    pY = sum(rowW(1:(min(rows)-1))) * 10000;

                    tileNumStr = num2str(t - 1); % 0-based index for XML
                    
                    % Create the Tile metadata node
                    newTileNode = obj.xmlDocument.createElement(obj.sessionTileNode);
                    newTileNode.setAttribute(obj.fileTile, tileNumStr);
                    
                    % Save using standard legacy-compatible attributes
                    newTileNode.setAttribute('x', num2str(round(pX)));
                    newTileNode.setAttribute('y', num2str(round(pY)));
                    newTileNode.setAttribute(obj.tileW, num2str(round(pW)));
                    newTileNode.setAttribute(obj.tileH, num2str(round(pH)));
                    
                    newLayoutNode.appendChild(newTileNode);

                    % Handle file entries (children) for this specific tile
                    if iscell(layout.tileOccupancy)
                        tileData = layout.tileOccupancy{t};
                    else
                        tileData = layout.tileOccupancy(t);
                    end

                    if ~isempty(tileData.children)
                        for c = 1:numel(tileData.children)
                            % Extract file path from ID (editorFile_C:/path/to/file.m)
                            childID = tileData.children(c).id;
                            filePath = strrep(childID, 'editorFile_', '');

                            newFileNode = obj.xmlDocument.createElement(obj.sessionFileNode);
                            newFileNode.setAttribute(obj.fileName, filePath);
                            newFileNode.setAttribute(obj.fileTile, tileNumStr);
                            newSessionNode.appendChild(newFileNode);
                        end
                    end
                end

            else
                % --- LEGACY JAVA PATH --- %
                jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                nTileWH = jDesktop.getDocumentTiledDimension('Editor');
                newLayoutNode.setAttribute(obj.tileW, num2str(nTileWH.getWidth));
                newLayoutNode.setAttribute(obj.tileH, num2str(nTileWH.getHeight));

                [editorSummary, jEditorViewClient] = obj.getOpenEditorFiles();
                tiles = [];
                for i=1:length(editorSummary)
                    newFileNode = obj.xmlDocument.createElement(obj.sessionFileNode);
                    newFileNode.setAttribute(obj.fileName, editorSummary{i});

                    tile = jDesktop.getClientLocation(jEditorViewClient(i));
                    tileNumberValue = tile.getTile;
                    if tileNumberValue < 0 && ~tile.isExternal(), tileNumberValue = 0; end

                    isNewTile = isempty(tiles) || all(tileNumberValue ~= tiles);
                    if isNewTile
                        tiles = [tiles tileNumberValue]; %#ok<AGROW>
                        tileNumStr = num2str(tileNumberValue);

                        newTileNode = obj.xmlDocument.createElement(obj.sessionTileNode);
                        newTileNode.setAttribute(obj.fileTile, tileNumStr);
                        newTileNode.setAttribute(obj.tileH, num2str(tile.getFrameHeight));
                        newTileNode.setAttribute(obj.tileW, num2str(tile.getFrameWidth));
                        newTileNode.setAttribute(obj.tileX, num2str(tile.getFrameX));
                        newTileNode.setAttribute(obj.tileY, num2str(tile.getFrameY));
                        newLayoutNode.appendChild(newTileNode);
                    end

                    newFileNode.setAttribute(obj.fileTile, num2str(tileNumberValue));
                    newSessionNode.appendChild(newFileNode);
                end
            end
        end

        function deleteSessionNode(obj, sessionNode)
            % DELETESESSIONNODE Removes a specific session from the XML and saves to disk
            if ~isempty(sessionNode)
                parentSessionNode = sessionNode.getParentNode();
                if ~isempty(parentSessionNode)
                    parentSessionNode.removeChild(sessionNode);
                    obj.save();
                end
            end
        end

        function editSessionNode(obj, sessionNode, newName)
            % EDITSESSIONNODE Updates the name attribute of a session and saves to disk
            if ~isempty(sessionNode)
                sessionNode.setAttribute(obj.sessionName, newName);
                obj.save();
            end
        end

        function updateFile(obj, fileNode, newFileName)
            % UPDATEFILE Modifies, adds, or removes file entries within a session node.

            if isempty(newFileName)
                % Delete the node if newFileName is empty
                parentSessionNode = fileNode.getParentNode();
                if ~isempty(parentSessionNode)
                    parentSessionNode.removeChild(fileNode);
                end

            elseif iscellstr(newFileName) || (isstring(newFileName) && numel(newFileName) > 1)
                % Handle a list of filenames
                % Update the first node and insert clones for the rest
                fileLocation = newFileName{1};
                fileNode.setAttribute(obj.fileName, fileLocation);
                parentSessionNode = fileNode.getParentNode();
                for i = 2:length(newFileName)
                    fileLocation = newFileName{i};
                    fileNodeCopy = fileNode.cloneNode(true);
                    fileNodeCopy.setAttribute(obj.fileName, fileLocation);

                    % Insert before the current node to maintain relative order
                    parentSessionNode.insertBefore(fileNodeCopy, fileNode);
                end

            else
                % Update a single filename
                % If it's just a name+ext, resolve the full path using 'which'
                resolvedPath = which(newFileName);
                if ~isempty(resolvedPath)
                    fileNode.setAttribute(obj.fileName, resolvedPath);
                else
                    % Fallback: if 'which' can't find it, use the provided string directly
                    fileNode.setAttribute(obj.fileName, newFileName);
                end
            end

            % Commit changes to the XML file on disk
            obj.save();
        end

        function [T, sessions, files] = getSessions(obj)
            % GETSESSIONS Returns a table summarizing all saved sessions
            root = obj.xmlDocument.getDocumentElement;
            sessions = root.getElementsByTagName(obj.sessionNode);
            numSessions = sessions.getLength;

            % Initialize cell arrays for table columns
            sessionArray = cell(numSessions, 1);
            name = cell(numSessions, 1);
            currentFolder = cell(numSessions, 1);
            addPaths = cell(numSessions, 1);
            lastUsed = cell(numSessions, 1);
            lastSaved = cell(numSessions, 1);
            files = cell(numSessions, 1);
            numFiles = cell(numSessions, 1);

            for i = 1:numSessions
                session = sessions.item(i-1);
                sessionArray{i} = session;
                name{i} = char(session.getAttribute(obj.sessionName));
                currentFolder{i} = char(session.getAttribute(obj.sessionCurrentFolder));
                addPaths{i} = char(session.getAttribute(obj.sessionPathRecursiveAdd));
                lastUsed{i} = char(session.getAttribute(obj.sessionLastUsed));
                lastSaved{i} = char(session.getAttribute(obj.sessionLastSaved));

                % Get the file list for this session
                sessionFiles = session.getElementsByTagName(obj.sessionFileNode);
                files{i} = sessionFiles;
                numFiles{i} = sessionFiles.getLength;
            end

            index = (1:numSessions)';
            T = table(index, name, numFiles, currentFolder, addPaths, lastUsed, lastSaved);
        end

        function moveAllTiledViewsTo0(~, editorGroupMembers, jDesktop)
            % MOVEALLTILEVIEWS TO0 (Legacy Only)
            % Prevents Java Desktop from closing files during grid transitions 
            % by consolidating all editor tabs into the first tile (Index 0).
            
            for gMember = 1:length(editorGroupMembers)
                view = editorGroupMembers(gMember);
                location = jDesktop.getClientLocation(view);
                if ~isempty(location)
                    % Note: .getTile is a Java method on DTLocation
                    tNum = location.getTile;
                    if ~isempty(tNum) && tNum > 0
                        % Move to tile index 0
                        jDesktop.setClientLocation(view, ...
                            com.mathworks.widgets.desk.DTLocation.create(0));
                    end
                end
            end
        end

        function [layoutNode, layoutWH, tileTable] = getLayout(obj, session)
            layoutNodeList = session.getElementsByTagName(obj.sessionLayoutNode);
            if layoutNodeList.getLength == 0
                layoutNode = []; layoutWH = []; tileTable = []; return;
            end
            layoutNode = layoutNodeList.item(0);
            
            % Read Grid Dimensions
            W = str2double(layoutNode.getAttribute(obj.tileW));
            H = str2double(layoutNode.getAttribute(obj.tileH));
            layoutWH = [W H];
            
            tileNodes = layoutNode.getElementsByTagName(obj.sessionTileNode);
            numTiles = tileNodes.getLength;
            tile = zeros(numTiles, 1); x = zeros(numTiles, 1); y = zeros(numTiles, 1);
            w = zeros(numTiles, 1); h = zeros(numTiles, 1);
            
            for i = 1:numTiles
                node = tileNodes.item(i-1);
                tile(i) = str2double(node.getAttribute(obj.fileTile));
                x(i) = str2double(node.getAttribute('x'));
                y(i) = str2double(node.getAttribute('y'));
                w(i) = str2double(node.getAttribute(obj.tileW));
                h(i) = str2double(node.getAttribute(obj.tileH));
            end
            
            % Infer grid
            % Identify unique "breakpoints" for rows and columns
            uniqueX = sort(unique(x));
            uniqueY = sort(unique(y));
            
            % Map pixel positions to 0-based grid indices
            gx = zeros(numTiles, 1); gy = zeros(numTiles, 1);
            gw = zeros(numTiles, 1); gh = zeros(numTiles, 1);
            
            for i = 1:numTiles
                % Find which "bin" the pixel position falls into
                gx(i) = find(uniqueX == x(i)) - 1;
                gy(i) = find(uniqueY == y(i)) - 1;
                
                % Calculate spans: how many unique breakpoints does this tile cover?
                % We look at x + w to see where the tile ends
                endX = x(i) + w(i);
                endY = y(i) + h(i);
                
                % Spans = (Index of end breakpoint) - (Index of start breakpoint)
                % If endX doesn't match a breakpoint exactly, we find the closest one
                gw(i) = sum(uniqueX < endX) - gx(i);
                gh(i) = sum(uniqueY < endY) - gy(i);
            end
            
            tileTable = table(tile, x, y, w, h, gx, gy, gw, gh);
            tileTable = sortrows(tileTable, 'tile');
        end

    end

    methods (Static = true)

        function [tf, app] = isNewDesktop()
            % ISNEWDESKTOP Robust check for the Modern HTML5 Desktop engine
            % tf: true if the UI supports DocumentLayout logic
            % app: returns the RootApp instance for immediate use
            tf = false;
            app = [];
            try
                app = matlab.ui.container.internal.RootApp.getInstance();
                % In Modern UI, DocumentLayout is a struct with fields.
                % In Legacy/Dead Zone, it is typically a 1x1 struct with no fields.
                if ~isempty(app) && ~isempty(fieldnames(app.DocumentLayout))
                    tf = true;
                end
            catch
                % Fail-safe for older versions where RootApp doesn't exist
            end
        end

        function [fileNames, fileViewClients] = getOpenEditorFiles()
            % GETOPENEDITORFILES Retrieves paths of all open files in the Editor.
            % Works for both legacy Java and modern HTML (R2026a) environments.

            if EditorSessionCommander.isNewDesktop()
                % --- MODERN HTML PATH --- %
                allDocs = matlab.desktop.editor.getAll;
                fileNames = {allDocs.Filename}';
                % In the new architecture, we don't use Java ViewClients.
                % We return the AppContainerDocument handles or empty for compatibility.
                fileViewClients = arrayfun(@(d) d.Editor.AppContainerDocument, allDocs, 'UniformOutput', false);
            else
                % --- LEGACY JAVA PATH --- %
                try
                    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                    fileViewClients = jDesktop.getGroupMembers('Editor');
                    fileNames = cell(length(fileViewClients), 1);

                    for i = 1:length(fileViewClients)
                        % Java returns the Title (which might have '*' or [Read Only])
                        rawTitle = char(jDesktop.getTitle(fileViewClients(i)));

                        % Clean up the dirty Java title string
                        cleanedTitle = rawTitle;
                        if ~isempty(cleanedTitle) && cleanedTitle(end) == '*'
                            cleanedTitle = cleanedTitle(1:end-1);
                        end

                        readOnlyString = ' [Read Only]';
                        if contains(cleanedTitle, readOnlyString)
                            cleanedTitle = strrep(cleanedTitle, readOnlyString, '');
                        end
                        fileNames{i} = cleanedTitle;
                    end
                catch
                    fileNames = {};
                    fileViewClients = [];
                end
            end
        end

        function client = getOpenClientByFileName(fileName, jDesktop)
            % GETOPENCLIENTBYFILENAME Finds the UI handle/client for a specific file.
            % In R2026a, returns an AppContainerDocument. In Java, returns a ViewClient.

            if EditorSessionCommander.isNewDesktop()
                % --- MODERN HTML PATH --- %
                % Find the document in the modern editor API
                allDocs = matlab.desktop.editor.getAll;
                % Match by filename (absolute path)
                matchIdx = strcmp({allDocs.Filename}, fileName);

                if any(matchIdx)
                    matchedDoc = allDocs(find(matchIdx, 1));
                    client = matchedDoc.Editor.AppContainerDocument;
                else
                    % Fallback: try matching just the name+ext if the full path fails
                    [~, name, ext] = fileparts(fileName);
                    shortName = [name ext];
                    for i = 1:numel(allDocs)
                        [~, n, e] = fileparts(allDocs(i).Filename);
                        if strcmp([n e], shortName)
                            client = allDocs(i).Editor.AppContainerDocument;
                            return;
                        end
                    end
                    client = [];
                    warning('EditorSessionCommander:ClientNotFound', 'Cannot retrieve client view for %s', fileName);
                end

            else
                % --- LEGACY JAVA PATH --- %
                if nargin < 2
                    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                end

                client = jDesktop.getClient(fileName);
                if isempty(client)
                    % Check for unsaved '*'
                    client = jDesktop.getClient([fileName '*']);
                    if isempty(client)
                        % Check for ' [Read Only]'
                        client = jDesktop.getClient([fileName ' [Read Only]']);
                        if isempty(client)
                            warning('EditorSessionCommander:ClientNotFound', 'Cannot retrieve client view for %s', fileName);
                        end
                    end
                end
            end
        end

        function setTile(fileName, tile, jDesktop, externalDimsXYWH)
            % SETTILE Moves a specific file to a specific tile index.
            % Handles both legacy Java DTLocation and modern AppContainer Layouts.

            if nargin < 3 || isempty(jDesktop)
                % Only used for legacy path
                jDesktop = []; 
            end
            if nargin < 4, externalDimsXYWH = []; end

            [isNewUI,app] = EditorSessionCommander.isNewDesktop();

            if isNewUI
                % --- MODERN HTML PATH --- %

                % Grab the current layout state
                L = app.DocumentLayout;
                targetID = "editorFile_" + string(fileName);

                % Remove document from any existing tile first to avoid duplicates
                for t = 1:numel(L.tileOccupancy)
                    children = L.tileOccupancy{t}.children;
                    if ~isempty(children)
                        match = strcmp({children.id}, targetID);
                        if any(match)
                            L.tileOccupancy{t}.children(match) = [];
                            break;
                        end
                    end
                end

                % Determine destination tile index
                % Note: HTML tiles are 1-indexed. If 'tile' is 0, we'll map to 1.
                destTile = max(1, tile + 1); 

                % Ensure the layout has enough tiles defined
                if destTile > numel(L.tileOccupancy)
                    % If the requested tile doesn't exist, we default to tile 1
                    % or you could expand the gridDimensions here.
                    destTile = 1;
                end

                % Add the document to the new tile
                newDocEntry.id = char(targetID);
                if isempty(L.tileOccupancy{destTile}.children)
                    L.tileOccupancy{destTile}.children = newDocEntry;
                else
                    L.tileOccupancy{destTile}.children(end+1) = newDocEntry;
                end

                % Push the updated layout back to the engine
                app.DocumentLayout = L;

            else
                % --- LEGACY JAVA PATH --- %
                if isempty(jDesktop)
                    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                end

                % Note: Update the class name below to your renamed 'EditorSessionCommander'
                jEditorViewClient = EditorSessionCommander.getOpenClientByFileName(fileName, jDesktop);

                if isempty(jEditorViewClient), return; end

                if tile <= -1
                    currLocation = jDesktop.getClientLocation(jEditorViewClient);
                    if ~isempty(externalDimsXYWH)
                        x = int16(externalDimsXYWH(1));
                        y = int16(externalDimsXYWH(2));
                        w = int16(externalDimsXYWH(3));
                        h = int16(externalDimsXYWH(4));
                        externalLoction = com.mathworks.widgets.desk.DTLocation.createExternal(x,y,w,h);
                        jDesktop.setClientLocation(jEditorViewClient, externalLoction);
                    elseif currLocation.getTile ~= -1
                        externalLoction = com.mathworks.widgets.desk.DTLocation.createExternal;
                        jDesktop.setClientLocation(jEditorViewClient, externalLoction);
                    end
                else
                    jDesktop.setClientLocation(jEditorViewClient, ...
                        com.mathworks.widgets.desk.DTLocation.create(tile));
                end
            end
        end

        function openSession(NameIn, TreatmentOfOpenFiles)
            % OPENSESSION Entry point for restoring an editor state.
            % NameIn: Name of the session to load.
            % TreatmentOfOpenFiles: 'c' for close others, 'a' for append (logic usually follows in later blocks).

            % Initialize the class
            obj = EditorSessionCommander(); 
            [T, sessions, files] = obj.getSessions();

            % ----------------------------------------------------------- %
            % Block 1: Preparation
            % ----------------------------------------------------------- %

            % Session Selection Logic
            if nargin < 1 || isempty(NameIn)
                indexFound = chooseOption(T);
                while length(indexFound) > 1
                    disp('Please only choose one option.');
                    indexFound = chooseOption(T);
                end
                if isempty(indexFound), return; end
            else
                indexFound = [];
                % Search for the name in the summary table
                for iname = 1:size(T, 1)
                    if strcmp(T.name{iname}, NameIn)
                        indexFound = T.index(iname); 
                        break; 
                    end
                end

                if isempty(indexFound)
                    disp(['Session name "', NameIn, '" not recognized.']);
                    indexFound = chooseOption(T);
                    if isempty(indexFound), return; end
                end
            end

            % Update "Last Used" Metadata
            % indexFound is 1-based from table, XML items are 0-based
            sessionNode = sessions.item(indexFound - 1);
            dateTime = datestr(now);
            sessionNode.setAttribute(obj.sessionLastUsed, dateTime);
            obj.save(); % Commit the "Last Used" timestamp to XML

            % Environment Setup
            % Change MATLAB working directory to where the session was saved
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

            % Add sub-directories to path if recursive path was enabled
            if strcmpi(T.addPaths{indexFound}, 'true')
                addpath(genpath(pwd));
            end

            % ----------------------------------------------------------- %
            % Block 2: Layout Requirements & Cleanup
            % ----------------------------------------------------------- %
            % Calculate Tile Requirements
            numFilesCount = T.numFiles{indexFound};
            maxTiles = -1;
            tiles = zeros(numFilesCount, 1);
            
            for i = 1:numFilesCount
                fileNode = files{indexFound}.item(i-1);
                tileAttr = char(fileNode.getAttribute(obj.fileTile));
                if isempty(tileAttr)
                    tileVal = 0; 
                else
                    tileVal = str2double(tileAttr);
                end
                if tileVal > maxTiles
                    maxTiles = tileVal;
                end
                tiles(i) = tileVal;
            end
            
            numTilesNeeded = maxTiles + 1;
            tileCloseSensitive = (numTilesNeeded == 2);
            
            % Cleanup & Validation
            if ~obj.isNewUI
                % --- LEGACY JAVA PATH --- %
                jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                editorGroupMembers = jDesktop.getGroupMembers('Editor');
                
                % 1. Validate Invalid Views
                nInvalid = 0;
                for i = 1:length(editorGroupMembers)
                    clientView = editorGroupMembers(i);
                    if ~clientView.isValid
                        nInvalid = nInvalid + 1;
                        try
                            jDesktop.setClientLocation(clientView, ...
                                com.mathworks.widgets.desk.DTLocation.create(0));
                        catch
                        end
                    end
                end
                
                if nInvalid > 0
                    fprintf('Legacy: %d invalid views found. Attempted validation.\n', nInvalid);
                end

                % 2. Safety Move (Crucial for spanning/re-arranging)
                % This uses the flag to decide whether to move views to Tile 0 
                % to prevent the Desktop from "eating" files during the transition.
                if ~tileCloseSensitive
                    % We call it via the object since it should be a class method
                    obj.moveAllTiledViewsTo0(editorGroupMembers, jDesktop);
                end
            else
                % --- MODERN HTML PATH --- %
                % The Chromium/AppContainer engine does not suffer from the 
                % Java "Tile 0" file-eating bug, so tileCloseSensitive is not used here.
                if isempty(obj.hApp.DocumentLayout)
                    initLayout = struct();
                    initLayout.gridDimensions.w = 1;
                    initLayout.gridDimensions.h = 1;
                    initLayout.tileCount = 1;
                    initLayout.tileOccupancy = {struct('children', [])};
                    obj.hApp.DocumentLayout = initLayout;
                end
            end

            % ----------------------------------------------------------- %
            % Block 3: Layout Reconstruction (Grid & Spans)
            % ----------------------------------------------------------- %
            [layoutNode, layoutWH, tileTable] = obj.getLayout(sessionNode);
            if isempty(layoutNode)
                error('Session saved in improper XML format: no layout info');
            end
            
            numTiles = height(tileTable);

            if obj.isNewUI
                % --- MODERN HTML PATH --- %
                % We prepare the struct for the AppContainer. We don't apply it yet—
                % we wait until the files are actually opened in Block 4/5.
                W = layoutWH(1);
                H = layoutWH(2);
                
                % Initialize the modern Layout struct
                modernL = struct;
                modernL.gridDimensions.w = W;
                modernL.gridDimensions.h = H;
                modernL.tileCount = numTiles;
                
                % Calculate weights based on actual XML proportions
                uniqueX = sort(unique(tileTable.x));
                uniqueY = sort(unique(tileTable.y));
                allEdgesX = sort(unique([tileTable.x; tileTable.x + tileTable.w]));
                allEdgesY = sort(unique([tileTable.y; tileTable.y + tileTable.h]));
                
                modernL.columnWeights = diff(allEdgesX) / sum(diff(allEdgesX));
                modernL.rowWeights = diff(allEdgesY) / sum(diff(allEdgesY));
                
                % Reconstruct tileCoverage matrix (The "Span" logic)
                modernL.tileCoverage = zeros(H, W); 
                for i = 1:numTiles
                    tIdx = tileTable.tile(i) + 1; % 1-based index for the matrix
                    
                    % Map pixel positions to grid indices
                    gx = find(uniqueX == tileTable.x(i)) - 1;
                    gy = find(uniqueY == tileTable.y(i)) - 1;
                    gw = sum(allEdgesX < (tileTable.x(i) + tileTable.w(i))) - gx;
                    gh = sum(allEdgesY < (tileTable.y(i) + tileTable.h(i))) - gy;
                    
                    rStart = gy + 1; rEnd = gy + gh;
                    cStart = gx + 1; cEnd = gx + gw;
                    modernL.tileCoverage(rStart:rEnd, cStart:cEnd) = tIdx;
                end
                
                % Store this to apply after files are ready
                pendingLayout = modernL;
                
            else
                % --- LEGACY JAVA PATH --- %
                jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                
                if numTiles == 1
                    % Don't mess with tiles if already in single window mode
                    if jDesktop.getDocumentArrangement('Editor') ~= 1
                        jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(1,1));
                    end
                elseif numTiles > 0
                    W = layoutWH(1);
                    H = layoutWH(2);
                    NeedToReRearrangeLater = false;
                    currentArrangmentType = jDesktop.getDocumentArrangement('Editor');
                    
                    if currentArrangmentType == 1 && W*H == 2
                        NeedToReRearrangeLater = true;
                    end
                    
                    jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(W, H));
                    
                    if ~tileCloseSensitive
                        obj.moveAllTiledViewsTo0(editorGroupMembers, jDesktop); % Avoid eating files
                    end
                    
                    tilesOnly = tileTable(tileTable.tile >= 0, :);
                    [xu, ~, xui] = unique(tilesOnly.x);
                    c = (1:W)'; % Transpose for dimensional consistency
                    [yu, ~, yui] = unique(tilesOnly.y);
                    r = (1:H)';
                    [x2u, ~, x2ui] = unique(tilesOnly.x + tileTable.w(tileTable.tile >= 0));
                    c2 = (1:W)';
                    [y2u, ~, y2ui] = unique(tilesOnly.y + tileTable.h(tileTable.tile >= 0));
                    r2 = (1:H)';
                    
                    if length(xu) ~= W || length(yu) ~= H || length(x2u) ~= W || length(y2u) ~= H || numTiles ~= height(tilesOnly)
                        error('Inconsistent start/end values and number of rows/columns');
                    end
                    
                    columns = c(xui) - 1;
                    rows = r(yui) - 1;
                    columnSpan = c2(x2ui) - columns;
                    rowSpan = r2(y2ui) - rows;
                    
                    for i = 1:numTiles
                        if rowSpan(i) == 1 && columnSpan(i) == 1
                            % Do nothing
                        elseif rowSpan(i) == 1
                            jDesktop.setDocumentColumnSpan('Editor', rows(i), columns(i), columnSpan(i));
                        elseif columnSpan(i) == 1
                            jDesktop.setDocumentRowSpan('Editor', rows(i), columns(i), rowSpan(i));
                        else
                            for j = 0:rowSpan(i)-1
                                jDesktop.setDocumentColumnSpan('Editor', rows(i)+j, columns(i), columnSpan(i));
                            end
                            jDesktop.setDocumentRowSpan('Editor', rows(i), columns(i), rowSpan(i));
                        end
                    end
                end
            end

            % ----------------------------------------------------------- %
            % Block 4: Tile Stabilization (Marker Files)
            % ----------------------------------------------------------- %
            if ~obj.isNewUI
                % --- LEGACY JAVA PATH --- %
                % Ensure marker files exist to prevent grid collapse
                testFile = cell(numTiles, 1);
                
                % Locate the marker file package directory
                whatEditorLayout = what('+EditorSessionCommander');
                if isempty(whatEditorLayout)
                    % Fallback to current folder if package not on path
                    editorLayoutPath = pwd;
                else
                    editorLayoutPath = whatEditorLayout(1).path;
                end
                
                if exist('NeedToReRearrangeLater', 'var') && NeedToReRearrangeLater
                    testFile_ = cell(numTiles, 1);
                    for i = 1:numTiles
                        testFile_{i} = fullfile(editorLayoutPath, ['tile' num2str(i-1) '_.m']);
                        t1 = tic;
                        id = fopen(testFile_{i}, 'w');
                        while toc(t1) < 1 && ~exist(testFile_{i}, 'file')
                        end
                        fclose(id);
                        edit(testFile_{i});
                        obj.setTile(testFile_{i}, 0, jDesktop);
                    end
                    
                    jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(W, H));
                    
                    for i = 1:numTiles
                        testFile{i} = fullfile(editorLayoutPath, ['tile' num2str(i-1) '.m']);
                        t1 = tic;
                        id = fopen(testFile{i}, 'w');
                        while toc(t1) < 1 && ~exist(testFile{i}, 'file')
                        end
                        fclose(id);
                        edit(testFile{i});
                        obj.setTile(testFile{i}, i-1, jDesktop);
                    end
                else
                    for i = 1:numTiles
                        testFile{i} = fullfile(editorLayoutPath, ['tile' num2str(i-1) '.m']);
                        t1 = tic;
                        id = fopen(testFile{i}, 'w');
                        while toc(t1) < 1 && ~exist(testFile{i}, 'file')
                        end
                        fclose(id);
                        edit(testFile{i});
                        obj.setTile(testFile{i}, i-1, jDesktop);
                    end
                end
            else
                % --- MODERN HTML PATH --- %
                % Modern UI handles grid structure via the AppContainer logic.
                % Marker files are unnecessary here as we will apply 'pendingLayout'
                % once the actual session files are opened.
                testFile = {}; 
            end

            % ----------------------------------------------------------- %
            % Block 5: File Reconciliation & Opening
            % ----------------------------------------------------------- %
            
            % Get currently open files (using our modernized static method)
            [editorOpenFileNames, ~] = EditorSessionCommander.getOpenEditorFiles();
            
            % Generate a list of short names (name+ext) for fuzzy matching
            editorShortNames = cell(size(editorOpenFileNames));
            for i = 1:length(editorOpenFileNames)
                [~, n, e] = fileparts(editorOpenFileNames{i});
                editorShortNames{i} = [n e];
            end
            
            numSessionFiles = T.numFiles{indexFound};
            fileNodes = files{indexFound};
            
            % Create a static array of nodes to avoid indexing issues if we delete nodes
            staticFileNodeArray = cell(1, numSessionFiles);
            for i = 1:numSessionFiles
                staticFileNodeArray{i} = fileNodes.item(i-1);
            end
            
            % Tracking arrays
            sessionFileStatus = -ones(numSessionFiles, 1);
            sessionTileStatus = zeros(numSessionFiles, 1);
            tileFileCorrelation = cell(numSessionFiles, 1);
            editorFileStatus = false(size(editorOpenFileNames)); % Which open files to keep
            
            for i = 1:numSessionFiles
                fileNode = staticFileNodeArray{i};
                sessionFullPath = char(fileNode.getAttribute(obj.fileName));
                [~, n, e] = fileparts(sessionFullPath);
                sessionShortName = [n e];
                
                % Comparison Logic
                % 1: Exact Path Match + Open
                % 2: Exact Path Match + Exists on disk (but closed)
                % 3: Short Name Match + Open (Different directory)
                % 4: Short Name Match + Exists on path (Different directory)
                
                if any(strcmp(sessionFullPath, editorOpenFileNames))
                    matchCase = 1;
                elseif exist(sessionFullPath, 'file')
                    matchCase = 2;
                elseif any(strcmp(sessionShortName, editorShortNames))
                    matchCase = 3;
                elseif ~isempty(which(sessionShortName))
                    matchCase = 4;
                else
                    matchCase = -1;
                end
                
                sessionFileStatus(i) = matchCase;
                
                switch matchCase
                    case -1 % Not found anywhere
                        fprintf(2, 'Warning: File "%s" not found.\n', sessionFullPath);
                        resp = input('Remove from session [y/n]? ', 's');
                        if strcmpi(resp, 'y'), obj.updateFile(fileNode, []); end
                        
                    case 1 % Found and already open
                        editorFileStatus(strcmp(sessionFullPath, editorOpenFileNames)) = true;
                        sessionTileStatus(i) = 1;
                        tileFileCorrelation{i} = sessionFullPath;
                        
                    case 2 % Found on disk, need to open
                        matlab.desktop.editor.openDocument(sessionFullPath);
                        sessionTileStatus(i) = 1;
                        tileFileCorrelation{i} = sessionFullPath;
                        
                    case 3 % Open, but path is different
                        possibleMatches = strcmp(sessionShortName, editorShortNames);
                        fprintf('Warning: "%s" is open from a different location.\n', sessionShortName);
                        resp = input('[1] Leave open, [2] Update session path, [3] Close/Remove, [Any] Skip: ', 's');
                        
                        if isempty(resp), resp = '0'; end
                        switch resp
                            case '1'
                                editorFileStatus(possibleMatches) = true;
                                sessionTileStatus(i) = 1;
                                tileFileCorrelation{i} = editorOpenFileNames{find(possibleMatches,1)};
                            case '2'
                                editorFileStatus(possibleMatches) = true;
                                matchedPath = editorOpenFileNames(possibleMatches);
                                obj.updateFile(fileNode, matchedPath);
                                sessionTileStatus(i) = 1;
                                tileFileCorrelation{i} = matchedPath{1};
                            case '3'
                                obj.updateFile(fileNode, []);
                        end
                        
                    case 4 % Not open, but exists elsewhere on path
                        fprintf('Warning: "%s" found at: %s\n', sessionShortName, which(sessionShortName));
                        resp = input('[1] Open & Update Session, [2] Remove from Session, [3] Open (Keep XML path): ', 's');
                        
                        resolvedPath = which(sessionShortName);
                        switch resp
                            case '1'
                                matlab.desktop.editor.openDocument(resolvedPath);
                                obj.updateFile(fileNode, resolvedPath);
                                sessionTileStatus(i) = 1;
                                tileFileCorrelation{i} = resolvedPath;
                            case '2'
                                obj.updateFile(fileNode, []);
                            case '3'
                                matlab.desktop.editor.openDocument(resolvedPath);
                                sessionTileStatus(i) = 1;
                                tileFileCorrelation{i} = resolvedPath;
                        end
                end
            end

            % ----------------------------------------------------------- %
            % Block 6: Tile Correlation & Coordinate Mapping
            % ----------------------------------------------------------- %

            if obj.isNewUI
                % --- MODERN HTML PATH --- %
                % In the new system, we don't need to "test" where tiles are.
                % The tile IDs we set in pendingLayout.tileCoverage are absolute.
                % We just map our requested tiles directly.
                actualTile = tiles; 

            else
                % --- LEGACY JAVA PATH --- %
                % Maintain the original coordinate-checking logic for Java
                if numTilesNeeded > 1
                    % Extract geometry from table
                    realTiles = tileTable.tile >= 0;
                    x = tileTable.x(realTiles);
                    y = tileTable.y(realTiles);
                    w = tileTable.w(realTiles);
                    h = tileTable.h(realTiles);

                    % Set relative row/column sizes
                    dx = unique(x + w) - unique(x);
                    dy = unique(y + h) - unique(y);
                    jDesktop.setDocumentRowHeights('Editor', dy / sum(dy));
                    jDesktop.setDocumentColumnWidths('Editor', dx / sum(dx));

                    % Read back physical locations of marker files to correlate indices
                    xtest = zeros(numTilesNeeded, 1);
                    ytest = zeros(numTilesNeeded, 1);

                    for i = 1:numTilesNeeded
                        cont = true;
                        % Ensure Java hasn't reset the grid
                        currDim = jDesktop.getDocumentTiledDimension('Editor');
                        if currDim.width ~= W || currDim.height ~= H
                            error('EditorSessionCommander:LayoutError', 'Tile layout has been unset or corrupted.');
                        end

                        % Wait for Java to catch up and report coordinates
                        while cont
                            client = EditorSessionCommander.getOpenClientByFileName(testFile{i}, jDesktop);
                            loc = jDesktop.getClientLocation(client);
                            if isempty(loc), continue; end

                            xtest(i) = loc.getFrameX();
                            ytest(i) = loc.getFrameY();

                            % Check if the file has actually moved to a distinct location
                            if numTilesNeeded <= 1 || i == 1 || ...
                                    (xtest(i) ~= xtest(1) && xtest(i) ~= xtest(i-1) && xtest(i) > 0) || ...
                                    (ytest(i) ~= ytest(1) && ytest(i) ~= ytest(i-1) && ytest(i) > 0)
                                cont = false;
                            end
                        end
                    end

                    if any(xtest < 0) || any(ytest < 0)
                        error('EditorSessionCommander:CorrelationError', 'Invalid tile properties read during correlation.');
                    end

                    % Map coordinates to grid indices
                    [~, ~, xutesti] = unique(xtest);
                    [~, ~, yutesti] = unique(ytest);
                    columnsActual = c(xutesti) - 1;
                    rowsActual = r(yutesti) - 1;

                    % Correlate the specified XML tile with the actual Java tile index
                    actualTile = zeros(numTilesNeeded, 1);
                    for specifiedTile = 1:numTilesNeeded
                        rowReq = rows(specifiedTile);
                        colReq = columns(specifiedTile);

                        match = (rowReq == rowsActual & colReq == columnsActual);
                        if sum(match) ~= 1
                            error('EditorSessionCommander:CorrelationError', 'Could not find a unique tile correlation match.');
                        end
                        actualTile(specifiedTile) = find(match, 1, 'first') - 1;
                    end
                else
                    actualTile = tiles;
                end
            end

            % ----------------------------------------------------------- %
            % Block 7: Final Move, Closing Unwanted Files, and Cleanup
            % ----------------------------------------------------------- %

            if obj.isNewUI
                % --- MODERN HTML PATH --- %

                % 1. STRICT CLEANUP: Close any files NOT in this session
                % This prevents the "Unusable UI" bug by ensuring the Editor 
                % only has files that the layout explicitly knows about.
                allOpenDocs = matlab.desktop.editor.getAll;
                for d = 1:numel(allOpenDocs)
                    if ~any(strcmp(allOpenDocs(d).Filename, tileFileCorrelation))
                        allOpenDocs(d).closeNoPrompt();
                    end
                end
                drawnow;

                % 2. RECONSTRUCT GEOMETRY
                [~, layoutWH, tileTable] = obj.getLayout(sessions.item(indexFound-1));

                newLayout = struct();
                newLayout.gridDimensions.w = layoutWH(1);
                newLayout.gridDimensions.h = layoutWH(2);
                newLayout.tileCount = height(tileTable);
                
                % Calculate Row/Col Weights from pixel breakpoints
                % We take the difference between unique X/Y positions
                uniqueX = sort(unique(tileTable.x));
                uniqueY = sort(unique(tileTable.y));
                
                % To get the final width/height, we append the max (x+w) / (y+h)
                allEdgesX = sort(unique([tileTable.x; tileTable.x + tileTable.w]));
                allEdgesY = sort(unique([tileTable.y; tileTable.y + tileTable.h]));
                
                colWidths = diff(allEdgesX);
                rowHeights = diff(allEdgesY);
                rowWeights = rowHeights / sum(rowHeights);
                columnWeights = colWidths / sum(colWidths);
                
                % Build Coverage Map
                coverageMap = zeros(layoutWH(2), layoutWH(1)); 
                for i = 1:height(tileTable)
                    rStart = tileTable.gy(i) + 1;
                    rEnd   = tileTable.gy(i) + tileTable.gh(i);
                    cStart = tileTable.gx(i) + 1;
                    cEnd   = tileTable.gx(i) + tileTable.gw(i);
                    coverageMap(rStart:rEnd, cStart:cEnd) = i;
                end

                newLayout.rowWeights = rowWeights;
                newLayout.columnWeights = columnWeights;
                newLayout.tileCoverage = coverageMap;

                % 3. BUILD OCCUPANCY
                occ = repmat(struct('children', []), 1, newLayout.tileCount);
                for i = 1:newLayout.tileCount
                    origXMLID = tileTable.tile(i);
                    matchIdx = find(sessionTileStatus & (tiles == origXMLID));
                    kids = struct('id', {});
                    for j = 1:numel(matchIdx)
                        kids(j).id = "editorFile_" + string(tileFileCorrelation{matchIdx(j)});
                    end
                    occ(i).children = kids;
                end
                occ = occ';
                newLayout.tileOccupancy = occ;

                % For debugging:
                %{
                display(rowWeights);
                display(columnWeights);
                display(coverageMap);
                display(occ);
                %}

                % 4. THE DOUBLE-TAP: Atomic application with sync delay
                try

                    % First Pass: Resets the Grid containers
                    obj.hApp.DocumentLayout = newLayout;
                    drawnow;
                    pause(0.5); % Allow the DOM to create the tiles

                    % Second Pass: Snaps the tabs into the pre-created tiles
                    obj.hApp.DocumentLayout = newLayout;
                    drawnow;

                catch ME
                    warning('EditorSessionCommander:LayoutError', ...
                        'Failed to arrange tiles: %s', ME.message);
                end

            else
                % --- LEGACY JAVA PATH --- %
                % Move real files to their correlated tiles
                for i = 1:numSessionFiles
                    if sessionTileStatus(i)
                        if tiles(i) >= 0
                            moveToTile = actualTile(tiles(i)+1);
                            obj.setTile(tileFileCorrelation{i}, moveToTile, jDesktop);
                        else
                            % Handle External/Floating Windows
                            moveToTile = tiles(i);
                            extIdx = (tileTable.tile == moveToTile);
                            sessionEditor.setTile(tileFileCorrelation{i}, moveToTile, jDesktop, ...
                                [tileTable.x(extIdx), tileTable.y(extIdx), ...
                                tileTable.w(extIdx), tileTable.h(extIdx)]);
                        end
                    end
                end

                % Close marker files
                if numTilesNeeded > 1
                    for i = 1:numTilesNeeded
                        jDesktop.closeClient(testFile{i});
                        editorFileStatus = editorFileStatus | strcmp(testFile{i}, editorOpenFileNames);
                    end
                end

                % Close files not in session (Interactive logic)
                if any(editorFileStatus == 0)
                    % [Your original interactive loop for 'cki' remains here]
                    % (Omitting loop for brevity, but keep it in your .m file)
                end
            end

            % Final save of the XML to update timestamps
            obj.save();

            % Physical Cleanup of marker files (Generic)
            if ~isempty(testFile)
                for i = 1:length(testFile)
                    if exist(testFile{i}, 'file'), delete(testFile{i}); end
                end
            end
        end

        function saveSession(sessionName, addSubDirectoriesToPath)
            % SAVESESSION Static entry point to save current editor state to XML.
            % Usage: EditorSessionCommander.saveSession('MyProject', true)

            % Initialize the object (loads existing XML)
            obj = EditorSessionCommander();
            [T, sessions, ~] = obj.getSessions();

            % Interactive Name Selection
            if nargin == 0
                if height(T) > 0
                    fprintf(1, '\nExisting session files:\n');
                    disp(T);
                    sessionName = input('Choose a session to overwrite (Name or Index) or type a new name: ', 's');
                else
                    sessionName = input('Type a name for the new session: ', 's');
                end

                if isempty(sessionName)
                    fprintf('Warning: Save cancelled. No name provided.\n');
                    return;
                end
            end

            % Match Name or Index
            matchnum = 0;
            nameMatch = find(strcmp(sessionName, T.name), 1, 'last');

            if ~isempty(nameMatch)
                matchnum = nameMatch;
            else
                % Try to see if the user typed an index number
                idxMatch = str2double(sessionName);
                if ~isnan(idxMatch) && any(idxMatch == T.index)
                    matchnum = idxMatch;
                    sessionName = T.name{matchnum};
                end
            end

            % Overwrite vs. New Logic
            if matchnum ~= 0
                % Overwriting an existing session
                disp(['Overwriting existing session: ', sessionName]);
                % Preserve the previous "recursive path" setting if not provided
                if nargin < 2
                    addSubDirectoriesToPath = strcmpi(T.addPaths{matchnum}, 'true');
                end
                % Remove the old node before appending the fresh state
                obj.deleteSessionNode(sessions.item(matchnum - 1));
            else
                % Saving as a new session
                disp(['Saving as new session: ', sessionName]);
                if nargin < 2
                    % Note: Ensure inputLowerValidatedChar is in your path
                    resp = input('Include sub-directories in path when loaded (y/n)? ', 's');
                    if ~isempty(resp) && strcmpi(resp(1), 'y')
                        addSubDirectoriesToPath = true;
                    else
                        addSubDirectoriesToPath = false;
                    end
                end
            end

            % Execute the Save
            % appendSession now handles the Java/HTML branching internally
            obj.appendSession(sessionName, addSubDirectoriesToPath);
            obj.save();

            fprintf('Session "%s" saved successfully.\n', sessionName);
        end

        function saveAsSession(sessionName, addSubDirectoriesToPath)
            % SAVEASSESSION Directly appends a new session without checking for duplicates.

            % Interactive Name Collection
            if nargin < 1 || isempty(sessionName)
                sessionName = input('Please enter a name for this session: ', 's' );
                if isempty(sessionName)
                    fprintf('Warning: Save cancelled. No name provided.\n');
                    return;
                end
            end

            % Path Option Collection
            if nargin < 2
                % Using a simplified check for broader compatibility
                resp = input('Include sub-directories in path when loaded (y/n)? ', 's');
                if ~isempty(resp) && any(strcmpi(resp(1), {'y','t'}))
                    addSubDirectoriesToPath = true;
                else
                    addSubDirectoriesToPath = false;
                end
            end

            % Execute
            % Initialize the class
            obj = EditorSessionCommander();

            % appendSession handles the RootApp (HTML) vs MLDesktop (Java) logic
            obj.appendSession(sessionName, addSubDirectoriesToPath);
            obj.save();

            fprintf('Session "%s" created.\n', sessionName);
        end

        function deleteSession()
            % DELETESESSION Interactive CLI to remove sessions from the XML.
            obj = EditorSessionCommander();
            [T, sessions, ~] = obj.getSessions();

            if height(T) == 0
                disp('No sessions available to delete.');
                return;
            end

            % chooseOption is your external helper function
            indexFound = chooseOption(T);
            if isempty(indexFound), return; end

            % Internal helper to show what is about to be deleted
            displaySessionToDelete = @() fprintf('\nTarget session(s):\n%s\n', ...
                formattedTableString(T(indexFound,:)));

            % Using a simplified validation check
            fprintf('\nSelected for deletion:\n');
            disp(T(indexFound,:));
            response = input('Delete session(s)? [y/n]: ', 's');

            if ~isempty(response) && strcmpi(response(1), 'y')
                % Collect nodes first to avoid indexing shifts during deletion
                sessionsToDelete = cell(1, length(indexFound));
                for i = 1:length(indexFound)
                    sessionsToDelete{i} = sessions.item(indexFound(i)-1);
                end

                % Perform the deletions
                for i = 1:length(sessionsToDelete)
                    obj.deleteSessionNode(sessionsToDelete{i});
                end
                fprintf('Successfully deleted %d session(s).\n', length(indexFound));
            else
                disp('Deletion cancelled.');
            end
        end

        function renameSession()
            % RENAMESESSION Interactive CLI to change a session's name attribute.
            obj = EditorSessionCommander();
            [T, sessions, ~] = obj.getSessions();

            if height(T) == 0
                disp('No sessions available to rename.');
                return;
            end

            indexFound = chooseOption(T);
            while length(indexFound) > 1
                disp('Please only choose one option at a time for renaming.');
                indexFound = chooseOption(T);
            end
            if isempty(indexFound), return; end

            fprintf(1, '\nRenaming session:\n');
            disp(T(indexFound, :));

            newName = input('Enter the new name (or press Enter to cancel): ', 's');
            if isempty(newName)
                disp('Rename cancelled.');
                return;
            end

            % Update the XML node
            obj.editSessionNode(sessions.item(indexFound-1), newName);
            fprintf('Session renamed to "%s".\n', newName);
        end

        function viewSession()
            % VIEWSESSION Prints a detailed summary of a specific session's files and layout.
            obj = EditorSessionCommander();
            [T, sessions, files] = obj.getSessions();

            if height(T) == 0
                disp('No sessions available to view.');
                return;
            end

            % Use chooseOption to select the session
            indexFound = chooseOption(T);
            while length(indexFound) > 1
                disp('Please only choose one option.');
                indexFound = chooseOption(T);
            end
            if isempty(indexFound), return; end

            % Display Header Table
            fprintf(1, '\n--- Session Overview ---\n');
            disp(T(indexFound, :));

            % Display Individual File Nodes
            fprintf(1, 'Files in this session:\n');
            numFiles = T.numFiles{indexFound};
            for i = 1:numFiles
                fileNode = files{indexFound}.item(i-1);

                % Retrieve attributes
                fullPath = char(fileNode.getAttribute(obj.fileName));
                tileAttr = char(fileNode.getAttribute(obj.fileTile));

                % Escape backslashes for clean printing
                pathForPrint = strrep(fullPath, '\', '\\');

                if isempty(tileAttr)
                    fprintf(1, '  [?]: %s\n', pathForPrint);
                else
                    tileNum = str2double(tileAttr);
                    if tileNum <= -1
                        % Floating/External window
                        fprintf(1, '  F%d: %s\n', abs(tileNum), pathForPrint);
                    else
                        % Standard docked tile
                        fprintf(1, '  T%d: %s\n', tileNum, pathForPrint);
                    end
                end
            end

            % Display Layout Metadata
            sessionNode = sessions.item(indexFound-1);
            [~, layoutWH, tileTable] = obj.getLayout(sessionNode);

            fprintf(1, '\nGrid Dimensions (Cols x Rows):\n');
            if ~isempty(layoutWH)
                fprintf('  %d x %d\n', layoutWH(1), layoutWH(2));
            else
                disp('  No layout dimensions specified.');
            end

            if ~isempty(tileTable)
                fprintf(1, 'Tile Geometry Table:\n');
                disp(tileTable);
            end
        end

        function manageSessions()
            % MANAGESESSIONS Main interactive menu.
            % Launch this to save, open, rename, view, or delete sessions.

            choices = 'sorvde';
            descriptions = {
                'Save session'
                'Open session'
                'Rename session'
                'View session files and details'
                'Delete session'
                'Exit'};

            % Define callbacks
            callbacks = { ...
                @() EditorSessionCommander.saveSession();
                @() EditorSessionCommander.openSession();
                @() EditorSessionCommander.renameSession();
                @() EditorSessionCommander.viewSession();
                @() EditorSessionCommander.deleteSession();
                @() []}; % Exit case

            response = '';
            % Use strcmpi for case-insensitive exit check
            while ~strcmpi(response, 'e')
                % Note: Ensure inputLowerValidatedChar is accessible
                response = inputLowerValidatedChar('What would you like to do? ', ...
                    choices, @displayCommanderChoices);

                if isempty(response), continue; end

                ind = find(response == choices, 1, 'first');
                if ~isempty(ind)
                    % Execute the corresponding function
                    callbacks{ind}();
                end
            end

            function displayCommanderChoices()
                fprintf(1, '\n=== Editor Session Commander ===\n');
                for i = 1:length(choices)
                    fprintf(1, ' [%s] %s\n', choices(i), descriptions{i});
                end
            end
        end

        function dockEditor()
            % DOCKEDITOR: Forces Editor focus then sends Ctrl+Shift+D
            EditorSessionCommander.ensureEditorFocus();
            EditorSessionCommander.sendRobotKeys(                           ...
                [java.awt.event.KeyEvent.VK_CONTROL,                        ...
                 java.awt.event.KeyEvent.VK_SHIFT,                          ...
                 java.awt.event.KeyEvent.VK_D]);
            pause(0.5); % Allow layout to settle
        end

        function undockEditor()
            % UNDOCKEDITOR: Forces Editor focus then sends Ctrl+Shift+U
            EditorSessionCommander.ensureEditorFocus();
            EditorSessionCommander.sendRobotKeys(                           ...
                [java.awt.event.KeyEvent.VK_CONTROL,                        ...
                 java.awt.event.KeyEvent.VK_SHIFT,                          ...
                 java.awt.event.KeyEvent.VK_U]);
        end

        function ensureEditorFocus()
            % Ensures the Editor is the active window for the OS
            allDocs = matlab.desktop.editor.getAll;
            if ~isempty(allDocs)
                % Make the first document active in MATLAB
                allDocs(1).makeActive();
            else
                % If no files are open, create a temporary one
                matlab.desktop.editor.newDocument;
            end
            
            % Small pause to allow the Desktop to shift window focus
            pause(0.3);
        end

        function sendRobotKeys(keys)
            % Generic helper to press and release a sequence of keys
            import java.awt.Robot;
            try
                robot = Robot();
                % Press all in sequence
                for i = 1:length(keys)
                    robot.keyPress(keys(i));
                end
                % Release in reverse sequence
                for i = length(keys):-1:1
                    robot.keyRelease(keys(i));
                end
            catch
                % Robot might fail if no display is attached
            end
        end

    end

end

%% --- Local Helper Functions ---

function response = inputLowerValidatedChar(question, validResponses, predicate)
    % INPUTLOWERVALIDATEDCHAR Gets a single-character response from the user.
    % Ensures the input is one of the validResponses (case-insensitive).
    
    if nargin < 3
        predicate = [];
    end
    
    validResponses = lower(validResponses);
    response = [];
    
    % Loop until the user provides a valid character
    while isempty(response) || ~any(lower(response(1)) == validResponses)
        % Run the optional display function (e.g., show menu options)
        if ~isempty(predicate) && isa(predicate, 'function_handle')
            try
                predicate();
            catch
                % Silently continue if the predicate fails
            end
        end
    
        response = input(question, 's');
    
        % Check for empty input (just pressing Enter)
        if isempty(response)
            continue;
        end
    end
    
    % Return only the first character, normalized to lowercase
    response = lower(response(1));
end

function indexFound = chooseOption(T, dialogueInterface, TParent)
% CHOOSEOPTION Returns a valid row index from a table based on user input.
% Supports fuzzy name matching and index selection.

    if nargin < 3
        TParent = [];
    end
    
    % Default interface uses Command Window (standard for R2026a)
    if nargin < 2 || isempty(dialogueInterface)
        dialogueInterface.displayTable = @disp;
        dialogueInterface.requestInput = @(s) input(s, 's');
        dialogueInterface.displayText  = @disp;
    end
    
    checkTCompatible(T);
    isSubSelection = ~isempty(TParent);
    
    % Show the user the available options
    dialogueInterface.displayTable(T);
    
    userInput = dialogueInterface.requestInput('Please enter option index or name (Press Enter to cancel): ');
    
    % Handle Cancellation
    if isempty(userInput)
        if isSubSelection
            indexFound = chooseOption(TParent, dialogueInterface);
        else
            indexFound = [];
        end
        return;
    end
    
    % Check if input is a numeric index
    indexFound = str2double(userInput); % str2double is safer than str2num

    if isnan(indexFound)
        % It's a string name - perform Fuzzy Match
        % Order: Exact -> Case-Insensitive -> Partial -> Partial Case-Insensitive
        compareFunctions = {@strcmp, @strcmpi, @(s, n) strncmp(s, n, length(s)), @(s, n) strncmpi(s, n, length(s))};
        indexMatched = false;
        attempt = 1;
    
        while ~indexMatched
            if attempt <= 4
                % Extract the comparison logic
                logicalMatch = compareFunctions{attempt}(userInput, T.name);
    
                if any(logicalMatch)
                    if sum(logicalMatch) > 1
                        % Ambiguous match - filter table and ask again
                        dialogueInterface.displayText('Multiple names matched. Please refine selection:');
                        indexFound = chooseOption(T(logicalMatch, :), dialogueInterface, T);
                        indexMatched = true;
                    else
                        % Unique match found
                        indexFound = T.index(logicalMatch);
                        indexMatched = true;
                    end
                else
                    attempt = attempt + 1;
                end
            else
                % No matches found at any level
                dialogueInterface.displayText(['No match found for "', userInput, '". Please try again.']);
                indexFound = chooseOption(T, dialogueInterface, TParent);
                break;
            end
        end
    end

    % Post-Selection Validation
    if isSubSelection
        if isempty(indexFound)
            indexFound = chooseOption(TParent, dialogueInterface);
        elseif ~any(indexFound == T.index)
            dialogueInterface.displayText([num2str(indexFound) ' is not in the sub-selection. Try again.']);
            indexFound = chooseOption(T, dialogueInterface, TParent);
        end
    else
        % Final check: ensure the resulting indices actually exist in the table
        if ~isempty(indexFound)
            isValid = ismember(indexFound, T.index);
            if ~all(isValid)
                dialogueInterface.displayText('One or more indices are invalid. Please try again.');
                indexFound = chooseOption(T, dialogueInterface);
            end
        end
    end

    % Nested validation function
    function checkTCompatible(tab)
        vars = tab.Properties.VariableNames;
        if ~any(strcmp('index', vars)) || ~any(strcmp('name', vars))
            error('chooseOption:InvalidTable', 'Table must contain "index" and "name" columns.');
        end
    end

end