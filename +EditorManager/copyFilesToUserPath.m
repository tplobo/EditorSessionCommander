% --- EditorManager Installer Script ---
% Copies the EditorManager class and its dependencies to the user path
% so it's always available when MATLAB starts.

newClassName = 'EditorManager';
oldPackageName = 'editorLayout'; % For reference/cleanup
sourceLocation = which(newClassName);

if isempty(sourceLocation)
    fprintf(2, 'Error: %s.m not found on the current path!\n', newClassName);
    return
end

% 1. Determine the User Path
% Modern userpath returns a clean string; older versions might include a separator.
uPath = userpath;
if isempty(uPath)
    fprintf(2, 'Error: userpath is not set. Please set a userpath before running.\n');
    return
end
% Clean up any trailing semicolons or colons
uPath = regexprep(uPath, '[ pathsep ]', ''); 

% 2. Define Destination
% We are moving toward a flat structure or a new package. 
% For simplicity and portability, we'll put it directly in userpath.
destinationLocation = fullfile(uPath, [newClassName '.m']);

if strcmp(sourceLocation, destinationLocation)
    warning('EditorManager is already running from the user path. No copy needed.');
else
    try
        copyfile(sourceLocation, destinationLocation);
        fprintf('Copied %s to %s\n', newClassName, destinationLocation);
    catch ME
        fprintf(2, 'Failed to copy class file: %s\n', ME.message);
    end
end

% 3. Handle Dependencies
% Add any other helper files (like chooseOption.m) here.
dependencies = {'chooseOption'};
for i = 1:length(dependencies)
    origDepLocation = which(dependencies{i});
    if ~isempty(origDepLocation)
        try
            copyfile(origDepLocation, fullfile(uPath, [dependencies{i} '.m']));
            fprintf('Copied dependency: %s\n', dependencies{i});
        catch
            fprintf(2, 'Could not copy dependency: %s\n', dependencies{i});
        end
    else
        fprintf(2, 'Warning: Dependency %s not found on path.\n', dependencies{i});
    end
end

disp('--- Setup Complete ---');
disp('EditorManager is now installed in your userpath.');