function indexFound = chooseOption(T, dialogueInterface, TParent)
% CHOOSEOPTION Returns a valid row index from a table based on user input.
% Supports fuzzy name matching and index selection.

if nargin < 3
    TParent = [];
end

% Default interface uses Command Window (standard for R2026a)
if nargin < 2 || isempty(dialogueInterface)
    dialogueInterface.displayTable = @disp;
    dialogueInterface.requestInput = @(s) input(s, 's');
    dialogueInterface.displayText  = @disp;
end

checkTCompatible(T);
isSubSelection = ~isempty(TParent);

% Show the user the available options
dialogueInterface.displayTable(T);

userInput = dialogueInterface.requestInput('Please enter option index or name (Press Enter to cancel): ');

% Handle Cancellation
if isempty(userInput)
    if isSubSelection
        indexFound = chooseOption(TParent, dialogueInterface);
    else
        indexFound = [];
    end
    return;
end

% Check if input is a numeric index
indexFound = str2double(userInput); % str2double is safer than str2num

if isnan(indexFound)
    % It's a string name - perform Fuzzy Match
    % Order: Exact -> Case-Insensitive -> Partial -> Partial Case-Insensitive
    compareFunctions = {@strcmp, @strcmpi, @(s, n) strncmp(s, n, length(s)), @(s, n) strncmpi(s, n, length(s))};
    indexMatched = false;
    attempt = 1;
    
    while ~indexMatched
        if attempt <= 4
            % Extract the comparison logic
            logicalMatch = compareFunctions{attempt}(userInput, T.name);
            
            if any(logicalMatch)
                if sum(logicalMatch) > 1
                    % Ambiguous match - filter table and ask again
                    dialogueInterface.displayText('Multiple names matched. Please refine selection:');
                    indexFound = chooseOption(T(logicalMatch, :), dialogueInterface, T);
                    indexMatched = true;
                else
                    % Unique match found
                    indexFound = T.index(logicalMatch);
                    indexMatched = true;
                end
            else
                attempt = attempt + 1;
            end
        else
            % No matches found at any level
            dialogueInterface.displayText(['No match found for "', userInput, '". Please try again.']);
            indexFound = chooseOption(T, dialogueInterface, TParent);
            break;
        end
    end
end

% Post-Selection Validation
if isSubSelection
    if isempty(indexFound)
        indexFound = chooseOption(TParent, dialogueInterface);
    elseif ~any(indexFound == T.index)
        dialogueInterface.displayText([num2str(indexFound) ' is not in the sub-selection. Try again.']);
        indexFound = chooseOption(T, dialogueInterface, TParent);
    end
else
    % Final check: ensure the resulting indices actually exist in the table
    if ~isempty(indexFound)
        isValid = ismember(indexFound, T.index);
        if ~all(isValid)
            dialogueInterface.displayText('One or more indices are invalid. Please try again.');
            indexFound = chooseOption(T, dialogueInterface);
        end
    end
end

    % Nested validation function
    function checkTCompatible(tab)
        vars = tab.Properties.VariableNames;
        if ~any(strcmp('index', vars)) || ~any(strcmp('name', vars))
            error('chooseOption:InvalidTable', 'Table must contain "index" and "name" columns.');
        end
    end
end