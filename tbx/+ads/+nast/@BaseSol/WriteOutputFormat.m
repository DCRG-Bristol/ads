function WriteOutputFormat(obj,fid,Type,N,IDs,outRequest)
    arguments
        obj
        fid
        Type char {mustBeMember(Type,{'DISPLACEMENT','FORCE','STRESS','STRAIN','VECTOR'})}
        N double
        IDs
        outRequest string = ["SORT1","REAL"]
    end

    % input validation
    if ~isscalar(IDs) && (any(isnan(IDs)) || any(isinf(IDs)))
        error('If specifying multiple output IDs, cannot include NaN or Inf values');
    end
    % write output requests.
    if ~obj.WriteToF06
        outRequest = [outRequest,"PLOT"];
    end
    outRqstStr = [Type,'(',char(strjoin(unique(upper(outRequest)),',')),')'];
    if isempty(IDs) || isinf(IDs)
        IDset = 'ALL';
    elseif any(isnan(IDs))
        IDset = 'NONE';
    else
        mni.printing.cases.SET(N,IDs).writeToFile(fid);
        IDset = num2str(IDs);
    end
    println(fid,[outRqstStr, ' = ', IDset]);
end


