function indexFound = chooseOption(T, dialogueInterface, TParent)
% CHOOSEOPTION Returns a valid row index of table T (needs 'index' and 'name'
% variables) from user input: index or name (exact, case-insensitive, partial,
% partial case-insensitive). Ambiguous names filter the table and ask again;
% Enter cancels ([]). dialogueInterface (optional) provides displayTable,
% requestInput and displayText function handles.

    if nargin < 3, TParent = []; end
    if nargin < 2 || isempty(dialogueInterface)
        dialogueInterface.displayTable = @disp;
        dialogueInterface.requestInput = @(s) input(s, 's');
        dialogueInterface.displayText  = @disp;
    end

    vars = T.Properties.VariableNames;
    if ~any(strcmp('index', vars)) || ~any(strcmp('name', vars))
        error('chooseOption:InvalidTable', 'Table must contain "index" and "name" columns.');
    end
    isSubSelection = ~isempty(TParent);

    dialogueInterface.displayTable(T);
    userInput = dialogueInterface.requestInput('Please enter option index or name (Press Enter to cancel): ');

    if isempty(userInput)
        if isSubSelection
            indexFound = chooseOption(TParent, dialogueInterface);
        else
            indexFound = [];
        end
        return;
    end

    indexFound = str2double(userInput);

    if isnan(indexFound)
        compareFunctions = {@strcmp, @strcmpi, ...
            @(s, n) strncmp(s, n, length(s)), @(s, n) strncmpi(s, n, length(s))};
        indexMatched = false;
        attempt = 1;
        while ~indexMatched
            if attempt <= 4
                logicalMatch = compareFunctions{attempt}(userInput, T.name);
                if any(logicalMatch)
                    if sum(logicalMatch) > 1
                        dialogueInterface.displayText('Multiple names matched. Please refine selection:');
                        indexFound = chooseOption(T(logicalMatch, :), dialogueInterface, T);
                    else
                        indexFound = T.index(logicalMatch);
                    end
                    indexMatched = true;
                else
                    attempt = attempt + 1;
                end
            else
                dialogueInterface.displayText(['No match found for "', userInput, '". Please try again.']);
                indexFound = chooseOption(T, dialogueInterface, TParent);
                break;
            end
        end
    end

    if isSubSelection
        if isempty(indexFound)
            indexFound = chooseOption(TParent, dialogueInterface);
        elseif ~any(indexFound == T.index)
            dialogueInterface.displayText([num2str(indexFound) ' is not in the sub-selection. Try again.']);
            indexFound = chooseOption(T, dialogueInterface, TParent);
        end
    elseif ~isempty(indexFound) && ~all(ismember(indexFound, T.index))
        dialogueInterface.displayText('One or more indices are invalid. Please try again.');
        indexFound = chooseOption(T, dialogueInterface);
    end
end