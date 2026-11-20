function [fileNames, fileViewClients] = getOpenEditorFiles(isNewUI)
% GETOPENEDITORFILES Paths of all open files in the Editor (column cellstr).
% fileViewClients: Java view clients (legacy only; [] on the modern desktop).
    if isNewUI
        allDocs = matlab.desktop.editor.getAll;
        if isempty(allDocs)
            fileNames = cell(0, 1);
        else
            fileNames = {allDocs.Filename}';
        end
        fileViewClients = [];
    else
        try
            jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            fileViewClients = jDesktop.getGroupMembers('Editor');
            fileNames = cell(length(fileViewClients), 1);
            for i = 1:length(fileViewClients)
                % The Java title may carry a trailing '*' or ' [Read Only]'
                title = char(jDesktop.getTitle(fileViewClients(i)));
                if ~isempty(title) && title(end) == '*'
                    title = title(1:end-1);
                end
                fileNames{i} = strrep(title, ' [Read Only]', '');
            end
        catch
            fileNames = {};
            fileViewClients = [];
        end
    end
end