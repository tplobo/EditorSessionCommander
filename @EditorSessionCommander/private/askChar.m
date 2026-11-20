function response = askChar(question, validResponses, predicate)
% ASKCHAR Single-character, case-insensitive answer that must be one of
% validResponses; asked again until valid. predicate (optional function
% handle) runs before each prompt, e.g. to print a menu.
    if nargin < 3, predicate = []; end
    validResponses = lower(validResponses);
    response = [];

    while isempty(response) || ~any(lower(response(1)) == validResponses)
        if isa(predicate, 'function_handle')
            try
                predicate();
            catch
            end
        end
        response = input(question, 's');
    end
    response = lower(response(1));
end