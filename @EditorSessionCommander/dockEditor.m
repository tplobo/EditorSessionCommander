function dockEditor(docked)
% DOCKEDITOR Docks (default) or undocks the Editor with Ctrl+Shift+D / U.
%   EditorSessionCommander.dockEditor()        % dock
%   EditorSessionCommander.dockEditor(false)   % undock
% Legacy desktop with no open files: nothing to (un)dock, so do nothing
% (this avoids creating, and then saving, an empty "untitled" document).
    if nargin < 1 || isempty(docked), docked = true; end

    if isempty(matlab.desktop.editor.getAll) && ~EditorSessionCommander.isNewDesktop()
        return
    end

    focusEditor();
    if docked
        key = java.awt.event.KeyEvent.VK_D;
    else
        key = java.awt.event.KeyEvent.VK_U;
    end
    sendKeys([java.awt.event.KeyEvent.VK_CONTROL, java.awt.event.KeyEvent.VK_SHIFT, key]);
    if docked, pause(0.5); end   % allow the layout to settle
end

function focusEditor()
% Makes the Editor the active window for the OS.
    allDocs = matlab.desktop.editor.getAll;
    if ~isempty(allDocs)
        allDocs(1).makeActive();
    else
        matlab.desktop.editor.newDocument;   % modern desktop only: temporary document to get focus
    end
    pause(0.3);
end

function sendKeys(keys)
% Presses, then releases (in reverse order), a chord of java.awt.event.KeyEvent keys.
    try
        robot = java.awt.Robot();
        for i = 1:length(keys), robot.keyPress(keys(i)); end
        for i = length(keys):-1:1, robot.keyRelease(keys(i)); end
    catch
        % Robot might fail if no display is attached
    end
end