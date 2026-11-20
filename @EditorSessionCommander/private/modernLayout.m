function modernLayout(obj, tileTable, tiles, tileStatus, tileFile)
% MODERNLAYOUT (Modern HTML desktop only) Closes files that are not part of
% the session, then applies the session's grid and tile occupancy. Files in
% each tile keep the order in which they appear in the session XML.
% Debug trace: setenv('ESC_DEBUG', '1').

    keep = tileFile(tileStatus);
    allOpenDocs = matlab.desktop.editor.getAll;
    trace('modern: %d open documents, %d belong to the session', numel(allOpenDocs), numel(keep));

    % Close files NOT in this session so the layout is consistent
    nClosed = 0;
    for d = 1:numel(allOpenDocs)
        if ~any(strcmp(allOpenDocs(d).Filename, keep))
            allOpenDocs(d).closeNoPrompt();
            nClosed = nClosed + 1;
        end
    end
    drawnow;
    trace('modern: closed %d foreign documents', nClosed);

    newLayout = buildLayout(tileTable, tiles, tileStatus, tileFile);
    trace('modern: grid %dx%d, %d tiles, columnWeights [%s], rowWeights [%s]', ...
        newLayout.gridDimensions.w, newLayout.gridDimensions.h, newLayout.tileCount, ...
        num2str(newLayout.columnWeights(:)', '%.3f '), num2str(newLayout.rowWeights(:)', '%.3f '));

    % Double-tap: the first pass creates the grid, the second one snaps the tabs in
    try
        obj.hApp.DocumentLayout = newLayout;
        drawnow;
        trace('modern: first pass applied');
        pause(0.5);
        obj.hApp.DocumentLayout = newLayout;
        drawnow;
        trace('modern: second pass applied');
    catch ME
        trace('modern: FAILED (%s)', ME.message);
        warning('EditorSessionCommander:LayoutError', 'Failed to arrange tiles: %s', ME.message);
    end
end

function L = buildLayout(tileTable, tiles, tileStatus, tileFile)
% Builds the AppContainer DocumentLayout struct from the docked tiles of a
% session. Breakpoints come from the tiles' start coordinates, so small gaps
% between x+w and the next x (e.g. Java dividers) are absorbed.
    d = tileTable(tileTable.tile >= 0, :);
    n = height(d);
    ux = unique(d.x);  uy = unique(d.y);
    ex = [ux; max(d.x + d.w)];
    ey = [uy; max(d.y + d.h)];

    L = struct();
    L.gridDimensions.w = numel(ux);
    L.gridDimensions.h = numel(uy);
    L.tileCount = n;
    L.rowWeights = diff(ey) / sum(diff(ey));
    L.columnWeights = diff(ex) / sum(diff(ex));

    cov = zeros(numel(uy), numel(ux));
    for i = 1:n
        r0 = d.gy(i) + 1;  c0 = d.gx(i) + 1;
        cov(r0:r0 + max(d.gh(i), 1) - 1, c0:c0 + max(d.gw(i), 1) - 1) = i;
    end
    L.tileCoverage = cov;

    occ = repmat(struct('children', []), n, 1);
    for i = 1:n
        idx = find(tileStatus & (tiles == d.tile(i)));    % XML order = tab order
        kids = struct('id', {});
        for j = 1:numel(idx)
            kids(j).id = "editorFile_" + string(tileFile{idx(j)});
        end
        occ(i).children = kids;
    end
    L.tileOccupancy = occ;
end