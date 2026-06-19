function data = parseAvlText(filename, data)
%PARSEAVLTEXT  Scan a plain-text AVL output file for name/value pairs.

fid = fopen(filename, 'r');
if fid < 0
    return;
end

numPat = '[-+]?(?:\d+\.?\d*|\.\d+)(?:[eEdD][-+]?\d+)?';
linePat = ['(\w+)\s*(?:=\s*)?(', numPat, ')'];

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line), break; end

    [tokens, ~] = regexp(line, linePat, 'tokens', 'match');
    for ti = 1:numel(tokens)
        key = strtrim(tokens{ti}{1});
        val = str2double(tokens{ti}{2});
        if ~isnan(val) && ~isempty(key)
            key = regexprep(key, '[^a-zA-Z0-9_]', '_');
            key = matlab.lang.makeValidName(key);
            data.(key) = val;
        end
    end
end

fclose(fid);

end