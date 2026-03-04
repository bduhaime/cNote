<%
'!-- ------------------------------------------------------------------ -->
'!-- Copyright 2017-2021, Polaris Consulting, LLC. All Rights Reserved. -->
'!-- ------------------------------------------------------------------ -->

function randomString()

' dbug("start randomString()...")

    Randomize()

    dim CharacterSetArray
    CharacterSetArray = Array(_
        Array(7, "abcdefghijklmnopqrstuvwxyz"), _
        Array(1, "0123456789") _
    )

    dim i
    dim j
    dim Count
    dim Chars
    dim Index
    dim Temp

    for i = 0 to UBound(CharacterSetArray)

        Count = CharacterSetArray(i)(0)
        Chars = CharacterSetArray(i)(1)

        for j = 1 to Count

            Index = Int(Rnd() * Len(Chars)) + 1
            Temp = Temp & Mid(Chars, Index, 1)

        next

    next

    dim TempCopy

    do until Len(Temp) = 0

        Index = Int(Rnd() * Len(Temp)) + 1
        TempCopy = TempCopy & Mid(Temp, Index, 1)
        Temp = Mid(Temp, 1, Index - 1) & Mid(Temp, Index + 1)

    loop

    RandomString = TempCopy

' 	 dbug("end randomString()")

end function
%>
