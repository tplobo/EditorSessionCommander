function [tf, app] = isNewDesktop()
% ISNEWDESKTOP Robust check for the Modern HTML5 Desktop engine.
% tf: true if the UI supports DocumentLayout logic; app: the RootApp instance.
    tf = false;
    app = [];
    try
        app = matlab.ui.container.internal.RootApp.getInstance();
        if ~isempty(app) && ~isempty(fieldnames(app.DocumentLayout))
            tf = true;
        end
    catch
        % Older versions: RootApp doesn't exist
    end
end