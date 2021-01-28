$files = gc $args[0] | % {$_.replace("\","/")}
$destination_folder = $args[1]

Write-Verbose -Verbose $("Temp file with filelist - ARGS[0] = "+$args[0])
Write-Verbose -Verbose $("Destination Path - ARGS[1] = "+$args[1])

$ffmpeg = "D:\Download\ffmpeg-20200729-cbb6ba2-win64-static\ffmpeg.exe"

Write-Verbose -Verbose "==========================="
$files | % {"file $_"} | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "$($destination_folder)output.mp4"


Write-Verbose -Verbose "Done. Press ENTER to exit."
Read-Host 