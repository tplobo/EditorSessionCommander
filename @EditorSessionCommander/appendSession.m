function obj = appendSession(obj, sessionName, addSubDirectoriesToPath)
% APPENDSESSION Appends the current Editor state as a new Session node.
% Modern layouts are stored as pseudo-pixels (cumulative rounded edges, so
% x+w always equals the next tile's x) to stay compatible with the Java path.

    if nargin < 2, sessionName = ''; end
    if nargin < 3, addSubDirectoriesToPath = false; end

    if addSubDirectoriesToPath, recurseStr = 'true'; else, recurseStr = 'false'; end

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

        newLayoutNode.setAttribute(obj.tileW, num2str(layout.gridDimensions.w));
        newLayoutNode.setAttribute(obj.tileH, num2str(layout.gridDimensions.h));

        tc = layout.tileCoverage;
        colW = layout.columnWeights(:) / sum(layout.columnWeights);
        rowW = layout.rowWeights(:) / sum(layout.rowWeights);

        % Rounded cumulative edges: tile x/y = edge(start), w/h = edge(end) - edge(start)
        ex = round([0; cumsum(colW)] * obj.dispScale);
        ey = round([0; cumsum(rowW)] * obj.dispScale);

        for t = 1:numel(layout.tileOccupancy)
            [rows, cols] = find(tc == t);
            if isempty(rows), continue; end

            pX = ex(min(cols));   pW = ex(max(cols) + 1) - pX;
            pY = ey(min(rows));   pH = ey(max(rows) + 1) - pY;

            tileNumStr = num2str(t - 1); % 0-based index for XML

            newTileNode = obj.xmlDocument.createElement(obj.sessionTileNode);
            newTileNode.setAttribute(obj.fileTile, tileNumStr);
            newTileNode.setAttribute(obj.tileX, num2str(pX));
            newTileNode.setAttribute(obj.tileY, num2str(pY));
            newTileNode.setAttribute(obj.tileW, num2str(pW));
            newTileNode.setAttribute(obj.tileH, num2str(pH));
            newLayoutNode.appendChild(newTileNode);

            if iscell(layout.tileOccupancy)
                tileData = layout.tileOccupancy{t};
            else
                tileData = layout.tileOccupancy(t);
            end

            for c = 1:numel(tileData.children)
                % Extract file path from ID (editorFile_C:/path/to/file.m)
                filePath = regexprep(char(tileData.children(c).id), '^editorFile_', '');
                if isMarkerFile(filePath), continue; end

                newFileNode = obj.xmlDocument.createElement(obj.sessionFileNode);
                newFileNode.setAttribute(obj.fileName, filePath);
                newFileNode.setAttribute(obj.fileTile, tileNumStr);
                newSessionNode.appendChild(newFileNode);
            end
        end

    else
        % --- LEGACY JAVA PATH --- %
        jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
        nTileWH = jDesktop.getDocumentTiledDimension('Editor');
        newLayoutNode.setAttribute(obj.tileW, num2str(nTileWH.getWidth));
        newLayoutNode.setAttribute(obj.tileH, num2str(nTileWH.getHeight));

        [editorSummary, jEditorViewClient] = getOpenEditorFiles(false);
        tiles = [];
        for i = 1:length(editorSummary)
            if isMarkerFile(editorSummary{i}), continue; end

            newFileNode = obj.xmlDocument.createElement(obj.sessionFileNode);
            newFileNode.setAttribute(obj.fileName, editorSummary{i});

            tile = jDesktop.getClientLocation(jEditorViewClient(i));
            tileNumberValue = tile.getTile;
            if tileNumberValue < 0 && ~tile.isExternal(), tileNumberValue = 0; end

            isNewTile = isempty(tiles) || all(tileNumberValue ~= tiles);
            if tileNumberValue == -1 && ~isNewTile
                % Several external windows: give each one its own negative id
                tileNumberValue = min(tiles) - 1;
                isNewTile = true;
            end
            tileNumStr = num2str(tileNumberValue);

            if isNewTile
                tiles = [tiles tileNumberValue]; %#ok<AGROW>
                newTileNode = obj.xmlDocument.createElement(obj.sessionTileNode);
                newTileNode.setAttribute(obj.fileTile, tileNumStr);
                newTileNode.setAttribute(obj.tileH, num2str(tile.getFrameHeight));
                newTileNode.setAttribute(obj.tileW, num2str(tile.getFrameWidth));
                newTileNode.setAttribute(obj.tileX, num2str(tile.getFrameX));
                newTileNode.setAttribute(obj.tileY, num2str(tile.getFrameY));
                newLayoutNode.appendChild(newTileNode);
            end

            newFileNode.setAttribute(obj.fileTile, tileNumStr);
            newSessionNode.appendChild(newFileNode);
        end
    end
end