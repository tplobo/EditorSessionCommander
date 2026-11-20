%% ======================================================================
%% FILE: FILE_EXCHANGE/EditorSessionCommander/@EditorSessionCommander/private/legacyLayout.m
%% (replaces the previous version; no other package file changes)
%% ======================================================================
function state = legacyLayout(phase, varargin)
% LEGACYLAYOUT (Legacy Java desktop only) Two-phase restoration of the tile grid.
%   state = legacyLayout('prepare', layoutWH, tileTable, numTiles, tileCloseSensitive)
%       Resets the Editor to a clean 1x1 grid, rebuilds the WxH grid with
%       parked marker files, and places one verified marker per tile. If the
%       Desktop still collapses the grid midway, the markers are closed and
%       the build is retried (up to 3 attempts). Keep 'state' alive: it owns
%       an onCleanup that closes the marker tabs and deletes the marker
%       folder even if loading fails.
%   legacyLayout('finish', state, tileTable, tiles, tileStatus, tileFile, ...
%                editorFileStatus, editorOpenFileNames, treatment)
%       Correlates XML tiles with Java tiles via the markers, moves the
%       session files, removes the markers and closes foreign files.
%
% Debug trace: setenv('ESC_DEBUG', '1') prints every step with timings.
    switch phase
        case 'prepare', state = prepareGrid(varargin{:});
        case 'finish',  state = finishGrid(varargin{:});
        otherwise
            error('EditorSessionCommander:BadPhase', 'Unknown phase "%s".', phase);
    end
end

function state = prepareGrid(layoutWH, tileTable, numTiles, tileCloseSensitive)
    sweepStaleMarkers();
    jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    W = layoutWH(1);
    H = layoutWH(2);
    state = struct('jDesktop', jDesktop, 'W', W, 'H', H, 'numTiles', numTiles, ...
        'rows', [], 'columns', [], 'testFile', {{}}, 'markerDir', '', 'cleanup', []);
    trace('prepare: grid %dx%d, %d docked tiles, arrangement %d', W, H, numTiles, ...
        jDesktop.getDocumentArrangement('Editor'));

    % Validate invalid views
    members = jDesktop.getGroupMembers('Editor');
    nInvalid = 0;
    for i = 1:length(members)
        if ~members(i).isValid
            nInvalid = nInvalid + 1;
            try
                jDesktop.setClientLocation(members(i), com.mathworks.widgets.desk.DTLocation.create(0));
            catch
            end
        end
    end
    if nInvalid > 0
        fprintf('Legacy: %d invalid views found. Attempted validation.\n', nInvalid);
    end

    % Safety move: avoid the Desktop "eating" files while the grid changes
    if ~tileCloseSensitive, moveAllTiledViewsTo0(members, jDesktop); end

    if numTiles == 1
        % Don't touch the tiles if already in single-window mode
        if jDesktop.getDocumentArrangement('Editor') ~= 1
            jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(1, 1));
        end
        return
    elseif numTiles < 1
        return
    end

    % Rows / columns / spans of the docked tiles (pure computation)
    tilesOnly = tileTable(tileTable.tile >= 0, :);
    [xu, ~, xui] = unique(tilesOnly.x);
    [yu, ~, yui] = unique(tilesOnly.y);
    [x2u, ~, x2ui] = unique(tilesOnly.x + tilesOnly.w);
    [y2u, ~, y2ui] = unique(tilesOnly.y + tilesOnly.h);
    c = (1:W)';
    r = (1:H)';

    if length(xu) ~= W || length(yu) ~= H || length(x2u) ~= W || length(y2u) ~= H ...
            || numTiles ~= height(tilesOnly)
        error('EditorSessionCommander:LayoutError', ...
            'Inconsistent start/end values and number of rows/columns');
    end

    state.columns = c(xui) - 1;
    state.rows = r(yui) - 1;
    state.columnSpan = c(x2ui) - state.columns;
    state.rowSpan = r(y2ui) - state.rows;

    % Marker files live in a private temp folder (never in the project / pwd)
    markerDir = fullfile(tempdir, sprintf('ESC_markers_%s_%d', datestr(now, 'yyyymmddHHMMSS'), randi(1e6)));
    mkdir(markerDir);
    state.markerDir = markerDir;
    state.cleanup = onCleanup(@() removeMarkers(markerDir));

    % Build the grid. Every attempt starts from a clean 1x1 grid, because
    % building on top of an existing (possibly empty) tiled grid is what
    % made the Desktop collapse it. The retries are only a safety net.
    maxAttempts = 3;
    for attempt = 1:maxAttempts
        [ok, why, testFile] = buildGrid(state, tileCloseSensitive);
        if ok, break; end
        trace('attempt %d FAILED: %s', attempt, why);
        closeMarkerTabs();
        delete(fullfile(markerDir, '*.m'));
    end
    if ~ok
        error('EditorSessionCommander:LayoutError', ...
            'Could not build the %dx%d tile grid after %d attempts (last problem: %s).', ...
            W, H, maxAttempts, why);
    end
    state.testFile = testFile;
    trace('prepare: done (attempt %d)', attempt);
end

function [ok, why, testFile] = buildGrid(state, tileCloseSensitive)
% One attempt: reset to a clean 1x1 grid (every view in tile 0), build the
% WxH grid with parked markers, then place one verified marker per tile.
    jDesktop = state.jDesktop;
    W = state.W;  H = state.H;  numTiles = state.numTiles;
    ok = false;  why = '';
    testFile = cell(numTiles, 1);

    % Reset
    members = jDesktop.getGroupMembers('Editor');
    trace('attempt: grid before reset %s', gridString(jDesktop));
    moveAllTiledViewsTo0(members, jDesktop);
    jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(1, 1));
    waitForGrid(jDesktop, 1, 1, 5);
    pause(0.5);

    % Grid
    jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(W, H));
    if ~waitForGrid(jDesktop, W, H, 5)
        why = ['grid is ' gridString(jDesktop) ' after setDocumentArrangement'];
        return
    end
    if ~tileCloseSensitive, moveAllTiledViewsTo0(members, jDesktop); end

    for i = 1:numTiles
        rs = state.rowSpan(i);  cs = state.columnSpan(i);
        row = state.rows(i);    col = state.columns(i);
        if rs == 1 && cs == 1
            % Nothing to span
        elseif rs == 1
            jDesktop.setDocumentColumnSpan('Editor', row, col, cs);
        elseif cs == 1
            jDesktop.setDocumentRowSpan('Editor', row, col, rs);
        else
            for j = 0:rs-1
                jDesktop.setDocumentColumnSpan('Editor', row+j, col, cs);
            end
            jDesktop.setDocumentRowSpan('Editor', row, col, rs);
        end
    end
    if ~waitForGrid(jDesktop, W, H, 5)
        why = ['grid is ' gridString(jDesktop) ' after spans'];
        return
    end

    % Park markers in tile 0 while the grid is re-created
    for i = 1:numTiles
        openMarker(fullfile(state.markerDir, sprintf('ESC_marker_tile%d_.m', i-1)), 0, jDesktop);
    end
    jDesktop.setDocumentArrangement('Editor', 2, java.awt.Dimension(W, H));
    if ~waitForGrid(jDesktop, W, H, 5)
        why = ['grid is ' gridString(jDesktop) ' after re-arranging with parked markers'];
        return
    end

    % Real markers, one per tile
    for i = 1:numTiles
        testFile{i} = fullfile(state.markerDir, sprintf('ESC_marker_tile%d.m', i-1));
        openMarker(testFile{i}, i-1, jDesktop);
        [ok, why] = placeMarker(testFile{i}, i-1, jDesktop, W, H);
        if ~ok, return; end
    end

    % Final check: the grid survived and every marker is still in its tile
    for i = 1:numTiles
        [ok, why] = placeMarker(testFile{i}, i-1, jDesktop, W, H);
        if ~ok, return; end
    end
end

function state = finishGrid(state, tileTable, tiles, tileStatus, tileFile, ...
        editorFileStatus, editorOpenFileNames, treatment)
    jDesktop = state.jDesktop;
    W = state.W;  H = state.H;
    numTiles = state.numTiles;
    c = (1:W)';  r = (1:H)';
    trace('finish: start');

    if numTiles > 1 && numel(state.testFile) >= numTiles
        realTiles = tileTable.tile >= 0;
        x = tileTable.x(realTiles);
        y = tileTable.y(realTiles);
        w = tileTable.w(realTiles);
        h = tileTable.h(realTiles);

        dx = unique(x + w) - unique(x);
        dy = unique(y + h) - unique(y);
        jDesktop.setDocumentRowHeights('Editor', dy / sum(dy));
        jDesktop.setDocumentColumnWidths('Editor', dx / sum(dx));

        % Read back marker locations to correlate XML tiles with Java tiles
        xtest = zeros(numTiles, 1);
        ytest = zeros(numTiles, 1);
        for i = 1:numTiles
            if ~waitForGrid(jDesktop, W, H, 5)
                error('EditorSessionCommander:LayoutError', ...
                    ['Tile layout has been unset or corrupted: expected %dx%d, ', ...
                     'found %s while locating marker %d.'], W, H, gridString(jDesktop), i);
            end

            cont = true;
            t1 = tic;
            while cont
                client = getClient(state.testFile{i}, jDesktop, 1);
                loc = [];
                if ~isempty(client), loc = jDesktop.getClientLocation(client); end

                if ~isempty(loc)
                    xtest(i) = loc.getFrameX();
                    ytest(i) = loc.getFrameY();
                    if i == 1 || ...
                            (xtest(i) ~= xtest(1) && xtest(i) ~= xtest(i-1) && xtest(i) > 0) || ...
                            (ytest(i) ~= ytest(1) && ytest(i) ~= ytest(i-1) && ytest(i) > 0)
                        cont = false;
                    end
                end

                if cont
                    if toc(t1) > 10
                        error('EditorSessionCommander:CorrelationError', ...
                            'Timed out waiting for marker %d to settle in its tile.', i);
                    end
                    pause(0.1);
                end
            end
            trace('marker %d at frame (%d,%d)', i, xtest(i), ytest(i));
        end

        if any(xtest < 0) || any(ytest < 0)
            error('EditorSessionCommander:CorrelationError', 'Invalid tile properties read during correlation.');
        end

        [~, ~, xutesti] = unique(xtest);
        [~, ~, yutesti] = unique(ytest);
        columnsActual = c(xutesti) - 1;
        rowsActual = r(yutesti) - 1;

        actualTile = zeros(numTiles, 1);
        for specified = 1:numTiles
            match = (state.rows(specified) == rowsActual & state.columns(specified) == columnsActual);
            if sum(match) ~= 1
                error('EditorSessionCommander:CorrelationError', 'Could not find a unique tile correlation match.');
            end
            actualTile(specified) = find(match, 1) - 1;
        end
    else
        actualTile = (0:max(numTiles, 1)-1)';   % identity mapping
    end

    % Move the session files to their correlated tiles
    for i = 1:numel(tiles)
        if ~tileStatus(i), continue; end
        if tiles(i) >= 0
            setTile(tileFile{i}, actualTile(tiles(i)+1), jDesktop);
        else
            ext = (tileTable.tile == tiles(i));
            setTile(tileFile{i}, tiles(i), jDesktop, ...
                [tileTable.x(ext), tileTable.y(ext), tileTable.w(ext), tileTable.h(ext)]);
        end
    end

    % Close marker tabs and delete their temporary folder
    removeMarkers(state.markerDir);

    % Files that are not part of the session: 'c' closes them, otherwise keep (tile 0)
    for k = find(~editorFileStatus(:))'
        if strncmpi(treatment, 'c', 1)
            try
                doc = matlab.desktop.editor.findOpenDocument(editorOpenFileNames{k});
                if ~isempty(doc), doc.close(); end
            catch
                % Untitled/unresolvable documents are left alone
            end
        else
            setTile(editorOpenFileNames{k}, 0, jDesktop);
        end
    end
    trace('finish: done');
    state = [];
end

function moveAllTiledViewsTo0(members, jDesktop)
% Consolidates all editor tabs into tile 0 so the Desktop cannot close files
% while the grid changes.
    for i = 1:length(members)
        location = jDesktop.getClientLocation(members(i));
        if ~isempty(location)
            tNum = location.getTile;
            if ~isempty(tNum) && tNum > 0
                jDesktop.setClientLocation(members(i), com.mathworks.widgets.desk.DTLocation.create(0));
            end
        end
    end
end

function client = getClient(fileName, jDesktop, timeout)
% Java view client of an open file. Polls up to 'timeout' s because edit()
% registers the client asynchronously. Tries the path as given and its
% /var <-> /private/var (macOS symlink) twin; the title may carry '*' or
% ' [Read Only]'.
    names = {fileName};
    if strncmp(fileName, '/private/', 9)
        names{end+1} = fileName(9:end);
    elseif strncmp(fileName, '/var/', 5)
        names{end+1} = ['/private' fileName];
    end
    suffixes = {'', '*', ' [Read Only]'};

    client = [];
    t0 = tic;
    while isempty(client)
        for n = 1:numel(names)
            for s = 1:numel(suffixes)
                client = jDesktop.getClient([names{n} suffixes{s}]);
                if ~isempty(client), break; end
            end
            if ~isempty(client), break; end
        end
        if ~isempty(client) || toc(t0) >= timeout, break; end
        pause(0.1);
    end
    if isempty(client)
        warning('EditorSessionCommander:ClientNotFound', 'Cannot retrieve client view for %s', fileName);
    end
end

function setTile(fileName, tile, jDesktop, externalXYWH)
% Moves a file to a docked tile (tile >= 0) or to an external window (tile <= -1).
    if nargin < 4, externalXYWH = []; end
    jClient = getClient(fileName, jDesktop, 5);
    if isempty(jClient), return; end

    if tile <= -1
        currLocation = jDesktop.getClientLocation(jClient);
        if ~isempty(externalXYWH)
            jDesktop.setClientLocation(jClient, com.mathworks.widgets.desk.DTLocation.createExternal( ...
                int16(externalXYWH(1)), int16(externalXYWH(2)), ...
                int16(externalXYWH(3)), int16(externalXYWH(4))));
        elseif currLocation.getTile ~= -1
            jDesktop.setClientLocation(jClient, com.mathworks.widgets.desk.DTLocation.createExternal);
        end
    else
        jDesktop.setClientLocation(jClient, com.mathworks.widgets.desk.DTLocation.create(tile));
    end
end

function [ok, why] = placeMarker(fileName, tile, jDesktop, W, H)
% Confirms that a marker sits in 'tile'. The Desktop applies client moves
% asynchronously, so the move is re-issued while it is lost, but ONLY while
% the WxH grid still exists: moving a client to a tile that no longer exists
% turns it into a floating window (tile -1), so a collapsed grid is reported
% immediately instead.
    ok = false;  why = '';
    t0 = tic;
    while toc(t0) < 8
        if ~waitForGrid(jDesktop, W, H, 0)
            why = sprintf('grid collapsed to %s while placing %s', gridString(jDesktop), shortName(fileName));
            return
        end
        client = getClient(fileName, jDesktop, 1);
        if ~isempty(client)
            loc = jDesktop.getClientLocation(client);
            if ~isempty(loc) && loc.getTile == tile
                trace('%s confirmed in tile %d (%.1fs)', shortName(fileName), tile, toc(t0));
                ok = true;
                return
            end
            if ~isempty(loc)
                trace('%s reported in tile %d, want %d: retry', shortName(fileName), loc.getTile, tile);
            end
            jDesktop.setClientLocation(client, com.mathworks.widgets.desk.DTLocation.create(tile));
        end
        pause(0.1);
    end
    why = sprintf('%s did not reach tile %d in 8 s', shortName(fileName), tile);
end

function s = gridString(jDesktop)
    d = jDesktop.getDocumentTiledDimension('Editor');
    s = sprintf('%dx%d', d.width, d.height);
end

function tf = waitForGrid(jDesktop, W, H, timeout)
% Waits until the Editor tile grid is WxH; false if it has not settled after 'timeout' s.
    t0 = tic;
    while true
        dims = jDesktop.getDocumentTiledDimension('Editor');
        tf = (dims.width == W && dims.height == H);
        if tf || toc(t0) >= timeout, return; end
        pause(0.1);
    end
end

function openMarker(markerFile, tile, jDesktop)
% Creates an empty marker file, opens it in the Editor and sends it to a tile.
    fid = fopen(markerFile, 'w');
    if fid == -1
        error('EditorSessionCommander:MarkerFailed', 'Could not create marker file %s', markerFile);
    end
    fclose(fid);
    edit(markerFile);
    setTile(markerFile, tile, jDesktop);
end

function closeMarkerTabs()
% Closes every marker tab (matched by file name, robust to symlinked temp paths).
    try
        allDocs = matlab.desktop.editor.getAll;
        for d = 1:numel(allDocs)
            [~, n, e] = fileparts(allDocs(d).Filename);
            if ~isempty(regexp([n e], '^ESC_marker_tile\d+_?\.m$', 'once'))
                allDocs(d).closeNoPrompt();
            end
        end
    catch
    end
end

function removeMarkers(markerDir)
% Closes the marker tabs and deletes the marker folder. Safe to call repeatedly.
    if isempty(markerDir), return; end
    closeMarkerTabs();
    if exist(markerDir, 'dir')
        try
            rmdir(markerDir, 's');
        catch
        end
    end
end

function sweepStaleMarkers()
% Deletes marker folders left in tempdir by a crashed MATLAB (older than a day).
    d = dir(fullfile(tempdir, 'ESC_markers_*'));
    for k = 1:numel(d)
        if d(k).isdir && now - d(k).datenum > 1
            try
                rmdir(fullfile(d(k).folder, d(k).name), 's');
            catch
            end
        end
    end
end

function s = shortName(p)
    [~, n, e] = fileparts(p);
    s = [n e];
end