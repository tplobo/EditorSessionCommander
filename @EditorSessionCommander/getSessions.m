function [T, sessions, files] = getSessions(obj)
% GETSESSIONS Returns a table summarizing all saved sessions, the session
% node list and, per session, the node list of its files.
    root = obj.xmlDocument.getDocumentElement;
    sessions = root.getElementsByTagName(obj.sessionNode);
    numSessions = sessions.getLength;

    name = cell(numSessions, 1);
    currentFolder = cell(numSessions, 1);
    addPaths = cell(numSessions, 1);
    lastUsed = cell(numSessions, 1);
    lastSaved = cell(numSessions, 1);
    files = cell(numSessions, 1);
    numFiles = cell(numSessions, 1);

    for i = 1:numSessions
        session = sessions.item(i-1);
        name{i} = char(session.getAttribute(obj.sessionName));
        currentFolder{i} = char(session.getAttribute(obj.sessionCurrentFolder));
        addPaths{i} = char(session.getAttribute(obj.sessionPathRecursiveAdd));
        lastUsed{i} = char(session.getAttribute(obj.sessionLastUsed));
        lastSaved{i} = char(session.getAttribute(obj.sessionLastSaved));

        files{i} = session.getElementsByTagName(obj.sessionFileNode);
        numFiles{i} = files{i}.getLength;
    end

    index = (1:numSessions)';
    T = table(index, name, numFiles, currentFolder, addPaths, lastUsed, lastSaved);
end