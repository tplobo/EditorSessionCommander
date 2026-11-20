function tf = isMarkerFile(filePath)
% ISMARKERFILE True for tile-marker files made by this class or by the legacy
% editorLayout package (they must never be stored in / restored from a session).
    tf = ~isempty(regexp(char(filePath), ...
        '(ESC_markers_[^\\/]*[\\/]ESC_marker_tile\d+_?\.m|[\\/]\+editorLayout[\\/]tile\d+_?\.m)$', 'once'));
end