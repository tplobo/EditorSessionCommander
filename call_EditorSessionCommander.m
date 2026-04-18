function call_EditorSessionCommander(name, mode)
    % Wrapper for EditorSessionCommander to handle OS-specific session
    % names and Project Root navigation.

    % 1. Validate session name
    if ~ischar(name) && ~isstring(name)
        error('The name for an Editor Session must be a character vector or string.');
    end
    
    % 2. Validate Operational System (Prefixing helps avoid path cross-contamination)
    if ismac
        name = ['mac-' char(name)];
    elseif isunix
        name = ['unx-' char(name)];
    elseif ispc
        name = ['win-' char(name)];
    else
        error('Platform not supported.');
    end
    
    % 3. Validate operation mode
    switch lower(mode)
        case {'save', 'load'}
            % Save current folder and go to root folder of current Project
            to_ProjectRoot('start');
            
            % Access editor session
            access_Session(name, mode);
            
            % Return to original folder
            to_ProjectRoot('end');
            
        case 'recuperate'
            % Direct access without project navigation
            access_Session(name, mode);
            
        otherwise
            error('Unknown mode. Use ''save'', ''load'', or ''recuperate''.');
    end
end

function to_ProjectRoot(mode)
    % Handles navigation to the Project Root and back
    prefdir_filename = fullfile(prefdir, 'TEMPORARY_NAVIGATION_PATH.txt');

    switch mode
        case 'start'
            % Save current folder path
            this_Folder = cd;
            file_id = fopen(prefdir_filename, 'w');
            if file_id ~= -1
                fprintf(file_id, '%s', this_Folder);
                fclose(file_id);
            end
            
            % Navigate to current Project Root
            try
                this_Project = currentProject;
                cd(this_Project.RootFolder);
            catch
                warning('No active MATLAB Project found. Staying in current folder.');
            end
            
        case 'end'
            % Load saved path and return
            if exist(prefdir_filename, 'file')
                file_id = fopen(prefdir_filename, 'r');
                this_Folder = fscanf(file_id, '%s');
                fclose(file_id);
                if exist(this_Folder, 'dir')
                    cd(this_Folder);
                end
                delete(prefdir_filename); % Clean up
            end
    end
end

function access_Session(name, mode)
    % Logic for interacting with the EditorManager class

    % Note: If you followed the previous step to put EditorManager 
    % in your userpath, you might not even need the addpath/rmpath logic here.
    path_ESM = fullfile('FILE_EXCHANGE', 'EditorManager');
    if exist(path_ESM, 'dir')
        addpath(genpath(path_ESM));
    end

    switch lower(mode)
        case {'save', 'recuperate'}
            % 0. Dock Editor to ensure `tileOccupancy` will not be empty
            EditorManager.dockEditor(); 

            % 1. Use the new class name
            % addSubDirectoriesToPath = false (per your original code)
            EditorManager.saveSession(name, false);
            
            % 2. Close Editor session
            % In R2026a, getAll().closeNoPrompt() is standard for the Editor API
            allDocs = matlab.desktop.editor.getAll;
            if ~isempty(allDocs)
                allDocs.closeNoPrompt();
            end
            
        case 'load'
            % 1. Use the new class name
            % 'c' = Close current files before opening session
            EditorManager.openSession(name, 'c'); 

            % 2. Undock Editor (personal preference)
            EditorManager.undockEditor(); 
            
        otherwise 
            % No action
    end
    
    % Clean up path if it was added locally
    if exist(path_ESM, 'dir')
        rmpath(genpath(path_ESM));
    end
end