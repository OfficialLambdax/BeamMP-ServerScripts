#NoTrayIcon

#cs
	Converts
        "TDannyboyT",
        "BadmanTru",
        "Carkid08",
        "Sauceguard",
        "Seas",
        "Casp0907",
        "zohh",
        "DK117",
        "iwantbweammep",

	To
		/event whitelist TDannyboyT BadmanTru Carkid08 Sauceguard Seas Casp0907 zohh DK117 iwantbweammep
#ce


Local $sInput = ClipGet()

; cleanse
$sInput = StringReplace($sInput, " ", "")
$sInput = StringReplace($sInput, @TAB, "")
$sInput = StringReplace($sInput, '"', "")
$sInput = StringReplace($sInput, ',', "")
$sInput = StringReplace($sInput, @CR, "")

; split
Local $arPlayers = StringSplit($sInput, @LF, 1)

; merge
Local $sOutput = "/event whitelist "
For $i = 1 To $arPlayers[0]
	$sOutput &= $arPlayers[$i]
	if $i < $arPlayers[0] then $sOutput &= " "
Next

ClipPut($sOutput)
