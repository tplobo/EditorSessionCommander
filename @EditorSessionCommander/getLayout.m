function [layoutNode, layoutWH, tileTable] = getLayout(obj, session)
% GETLAYOUT Reads a session's layout. tileTable columns: tile, x, y, w, h and
% the inferred 0-based grid position/span gx, gy, gw, gh (docked tiles only;
% external windows, tile < 0, get zeros).

    layoutNodeList = session.getElementsByTagName(obj.sessionLayoutNode);
    if layoutNodeList.getLength == 0
        layoutNode = []; layoutWH = []; tileTable = []; return;
    end
    layoutNode = layoutNodeList.item(0);

    layoutWH = [str2double(layoutNode.getAttribute(obj.tileW)), ...
                str2double(layoutNode.getAttribute(obj.tileH))];

    tileNodes = layoutNode.getElementsByTagName(obj.sessionTileNode);
    n = tileNodes.getLength;
    tile = zeros(n, 1); x = tile; y = tile; w = tile; h = tile;
    for i = 1:n
        node = tileNodes.item(i-1);
        tile(i) = str2double(node.getAttribute(obj.fileTile));
        x(i) = str2double(node.getAttribute(obj.tileX));
        y(i) = str2double(node.getAttribute(obj.tileY));
        w(i) = str2double(node.getAttribute(obj.tileW));
        h(i) = str2double(node.getAttribute(obj.tileH));
    end

    % Infer the grid from the docked tiles' breakpoints
    docked = tile >= 0;
    ux = sort(unique(x(docked)));
    uy = sort(unique(y(docked)));
    gx = zeros(n, 1); gy = gx; gw = gx; gh = gx;
    for i = find(docked)'
        gx(i) = find(ux == x(i), 1) - 1;
        gy(i) = find(uy == y(i), 1) - 1;
        gw(i) = sum(ux < x(i) + w(i)) - gx(i);
        gh(i) = sum(uy < y(i) + h(i)) - gy(i);
    end

    tileTable = sortrows(table(tile, x, y, w, h, gx, gy, gw, gh), 'tile');
end