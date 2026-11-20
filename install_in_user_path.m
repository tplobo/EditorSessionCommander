% Copies the class folder, the compatibility package and the wrapper to the
% user path so they exist when MATLAB starts (only needed for shortcuts or
% a startup.m; a project that adds the package folder itself does not need
% this). A copy in userpath can shadow the project's version: remove it
% again if you stop using it.
classFile = which('EditorSessionCommander');             % ...\@EditorSessionCommander\EditorSessionCommander.m
if isempty(classFile)
    fprintf(2, 'EditorSessionCommander is not on the path!\n'); return
end
srcRoot = fileparts(fileparts(classFile));
uPath = strtok(userpath, pathsep);
if isempty(uPath)
    fprintf(2, 'userpath is not set.\n'); return
end
if strcmp(srcRoot, uPath)
    warning('Already running from the user path. No copy needed.'); return
end
if exist(fullfile(uPath, 'EditorSessionCommander.m'), 'file')
    warning(['Old single-file EditorSessionCommander.m found in %s. ', ...
        'Delete it: it shadows the @EditorSessionCommander folder.'], uPath);
end
copyfile(fileparts(classFile), fullfile(uPath, '@EditorSessionCommander'));
copyfile(fullfile(srcRoot, '+editorLayout'), fullfile(uPath, '+editorLayout'));
copyfile(fullfile(srcRoot, 'call_EditorSessionCommander.m'), uPath);
disp('--- Installed in userpath ---');