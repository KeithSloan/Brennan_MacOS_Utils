property scriptPath : "/Users/ksloan/github/Brennan_MacOS_Utils/scripts/brennan_utils.sh"

on run
    try
        do shell script "bash " & quoted form of scriptPath
    on error errMsg number errNum
        if errNum is not -128 then
            display dialog "Error:" & return & errMsg buttons {"OK"} default button "OK" with icon stop
        end if
    end try
end run
