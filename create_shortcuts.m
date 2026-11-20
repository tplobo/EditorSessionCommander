% --- EditorSessionCommander Shortcut Creator ---
% This script creates shortcuts for Save, Open, and Manage sessions.
% It handles both legacy Java shortcuts and modern Toolstrip Favorites.

sCategory = EditorSessionCommander.shortcutCategory;
sNames = {EditorSessionCommander.shortcutSave; ...
          EditorSessionCommander.shortcutOpen; ...
          EditorSessionCommander.shortcutManageSessions};
sCallbacks = {'EditorSessionCommander.saveSession()'; ...
              'EditorSessionCommander.openSession()'; ...
              'EditorSessionCommander.manageSessions()'};

if EditorSessionCommander.isNewDesktop()
    fprintf('Modern Desktop: add these to Favorites manually:\n');
    for i = 1:numel(sNames)
        fprintf('  Label: %s\n  Code:  %s\n\n', sNames{i}, sCallbacks{i});
    end
else
    import com.mathworks.mlwidgets.shortcuts.ShortcutUtils;
    shortcutsJava = ShortcutUtils.getShortcutsByCategory(sCategory);
    existingNames = {};
    if ~isempty(shortcutsJava)
        for i = 0:shortcutsJava.size()-1
            existingNames{end+1} = char(shortcutsJava.elementAt(i).getLabel()); %#ok<SAGROW>
        end
    end
    for i = 1:numel(sNames)
        idx = find(strcmp(sNames{i}, existingNames), 1);
        if ~isempty(idx)    % update, preserving a customized icon
            icon = shortcutsJava.elementAt(idx-1).getIconPath();
            awtinvoke(ShortcutUtils, 'editShortcut', sNames{i}, sCategory, ...
                sNames{i}, sCategory, sCallbacks{i}, icon, 'true');
        else
            awtinvoke(ShortcutUtils, 'addShortcutToBottom', sNames{i}, ...
                sCallbacks{i}, [], sCategory, 'true');
        end
    end
    fprintf('Shortcuts added to the "%s" category.\n', sCategory);
end