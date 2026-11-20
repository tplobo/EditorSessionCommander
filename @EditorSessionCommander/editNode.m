function editNode(obj, action, node, value)
% EDITNODE Edits the XML and saves it to disk.
%   editNode(obj, 'delete', sessionNode)         remove a session
%   editNode(obj, 'rename', sessionNode, name)   rename a session
%   editNode(obj, 'file',   fileNode, value)     value: [] removes the entry;
%       a cellstr (or string array) replaces it with one entry per name;
%       a single name/path is resolved with 'which' when possible.
    if isempty(node), return; end

    switch lower(action)
        case 'delete'
            parent = node.getParentNode();
            if ~isempty(parent), parent.removeChild(node); end

        case 'rename'
            node.setAttribute(obj.sessionName, char(value));

        case 'file'
            if isempty(value)
                parent = node.getParentNode();
                if ~isempty(parent), parent.removeChild(node); end

            elseif iscellstr(value) || (isstring(value) && numel(value) > 1) %#ok<ISCLSTR>
                value = cellstr(value);
                node.setAttribute(obj.fileName, value{1});
                parent = node.getParentNode();
                for i = 2:numel(value)
                    nodeCopy = node.cloneNode(true);
                    nodeCopy.setAttribute(obj.fileName, value{i});
                    parent.insertBefore(nodeCopy, node);   % keeps relative order
                end

            else
                resolved = which(char(value));
                if isempty(resolved), resolved = char(value); end
                node.setAttribute(obj.fileName, resolved);
            end

        otherwise
            error('EditorSessionCommander:BadAction', 'Unknown action "%s".', action);
    end

    obj.save();
end