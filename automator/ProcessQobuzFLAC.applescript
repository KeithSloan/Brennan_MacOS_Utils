property scriptPath : "/Users/ksloan/github/Brennan_MacOS_Utils/scripts/process_qobuz_flac.sh"

on runScript(folderPath)
    try
        set output to do shell script "bash " & quoted form of scriptPath & " " & quoted form of folderPath
        -- script returns "OK:message" or "ERR:message"
        if output starts with "OK:" then
            display dialog (text 4 thru -1 of output) buttons {"OK"} default button "OK"
        else if output starts with "ERR:" then
            display dialog (text 5 thru -1 of output) buttons {"OK"} default button "OK" with icon caution
        end if
    on error errMsg
        display dialog "Error:" & return & errMsg buttons {"OK"} default button "OK" with icon stop
    end try
end runScript

on run
    try
        set f to choose folder with prompt "Select folder to process for Brennan:" default location (path to music folder)
        runScript(POSIX path of f)
    on error number -128
        -- user cancelled
    end try
end run

on open droppedItems
    repeat with f in droppedItems
        runScript(POSIX path of f)
    end repeat
end open
