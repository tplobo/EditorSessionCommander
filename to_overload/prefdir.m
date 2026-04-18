function output = prefdir()
    % Overload the 'prefdir' built-in matlab function, to change the save
    % location for the EditorSessionCommander package.
    
    % Start-up and shut-down functions directory
    functions_dir = 'PROJECT';
    
    % Define project 'preferences' directory (if project is open)
    try
        this_Project   	= currentProject;
        this_Project   	= this_Project.RootFolder;
        preferences_dir	= fullfile(this_Project,functions_dir);                         
    catch
        preferences_dir	= functions_dir;
    end
    preferences_dir     = fullfile(preferences_dir, 'project_preferences');
    
    % Create project 'preferences' directory
    if ~exist(preferences_dir, 'dir')
        mkdir(preferences_dir)
    end
    
    % Overload 'prefdir'
    output = preferences_dir;
end