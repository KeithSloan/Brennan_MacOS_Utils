property scriptPath : "/Users/ksloan/github/Brennan_MacOS_Utils/scripts/compare_nas_sonos.sh"

on run
    try
        set output to do shell script "bash " & quoted form of scriptPath
        if output starts with "OK:" then
            display dialog (text 4 thru -1 of output) buttons {"OK"} default button "OK"
        else if output starts with "ERR:" then
            display dialog (text 5 thru -1 of output) buttons {"OK"} default button "OK" with icon caution
        end if
    on error errMsg
        display dialog "Error:" & return & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end run
