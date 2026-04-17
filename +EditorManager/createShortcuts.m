% --- EditorManager Shortcut Creator ---
% This script creates shortcuts for Save, Open, and Manage sessions.
% It handles both legacy Java shortcuts and modern Toolstrip Favorites.

% 1. Setup Data
newClassName = 'EditorManager';

% Pull metadata from the class properties we defined earlier
sCategory = EditorManager.shortcutCategory;
sNames = {
    EditorManager.shortcutSave;
    EditorManager.shortcutOpen;
    EditorManager.shortcutManageSessions};

sCallbacks = {
    'EditorManager.saveSession()';
    'EditorManager.openSession()';
    'EditorManager.manageSessions()'};

% Check if we are in the modern Web Desktop
hApp = matlab.ui.container.internal.RootApp.getInstance();

if isempty(hApp)
    % --- LEGACY JAVA PATH ---
    % This handles the old "Shortcuts" bar in R2024b and earlier.
    
    import com.mathworks.mlwidgets.shortcuts.ShortcutUtils;
    
    shortcutsJava = ShortcutUtils.getShortcutsByCategory(sCategory);
    existingNames = {};
    if ~isempty(shortcutsJava)
        for i = 0:shortcutsJava.size()-1
            existingNames{end+1} = char(shortcutsJava.elementAt(i).getLabel()); %#ok<AGROW>
        end
    end

    for i = 1:length(sNames)
        matchIdx = find(strcmp(sNames{i}, existingNames), 1);
        if ~isempty(matchIdx)
            % Update existing
            icon = shortcutsJava.elementAt(matchIdx-1).getIconPath();
            awtinvoke(ShortcutUtils, 'editShortcut', ...
                sNames{i}, sCategory, sNames{i}, sCategory, sCallbacks{i}, icon, 'true');
        else
            % Add new
            awtinvoke(ShortcutUtils, 'addShortcutToBottom', ...
                sNames{i}, sCallbacks{i}, [], sCategory, 'true');
        end
    end
    fprintf('Java shortcuts added to the "%s" category.\n', sCategory);

else
    % --- MODERN R2026a PATH ---
    % In the Web Desktop, "Shortcuts" have been replaced by "Favorites".
    % There isn't currently a public Java-free API to programmatically 
    % inject buttons into the Toolstrip, so we use the Favorites mechanism.
    
    fprintf('Modern Desktop detected.\n');
    fprintf('Note: Programmatic Toolstrip injection is restricted in R2026a.\n');
    fprintf('Please add these to your "Favorites" gallery manually for the best experience:\n\n');
    
    for i = 1:length(sNames)
        fprintf('  [%d] Label: %s\n', i, sNames{i});
        fprintf('      Code:  %s\n\n', sCallbacks{i});
    end
    
    % Optional: Open the Favorites editor for the user
    try
        com.mathworks.mde.favorites.FavoritesBrowser.getInstance().showBrowser();
    catch
        % Browser not available or different API
    end
end

disp('Shortcut setup process complete.');