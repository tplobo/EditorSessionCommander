function trace(varargin)
% TRACE Prints a timestamped line when the environment variable ESC_DEBUG is
% set (setenv('ESC_DEBUG', '1')); silent otherwise. Shared by the legacy
% and modern layout code.
    if ~isempty(getenv('ESC_DEBUG'))
        fprintf('[ESC %s] ', datestr(now, 'HH:MM:SS.FFF'));
        fprintf(varargin{:});
        fprintf('\n');
    end
end