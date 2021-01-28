# minutes -> day
$day = "2021012*"

$ffmpeg = "D:\Download\ffmpeg-20200729-cbb6ba2-win64-static\ffmpeg.exe"
cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\

$days = (dir -Directory -Filter $day -Name) | % {$_.substring(0,8)} | select -Unique

$days | % {Write-Verbose -Verbose $_}

foreach ($aday in $days)
{

    Write-Verbose $aday
    if (($dailyvideos = (dir "$aday*" -Directory).count) -ge 1)
    {
        Write-Verbose -Verbose "**************** Processing $aday *********************"
        dir -Recurse "$($aday)*" | sort -pro fullname | % {"file $(($_.fullname).replace('\','/'))"}  | &$ffmpeg -protocol_whitelist file,pipe -f concat -safe 0 -i - -c:v copy -c:a aac "..\$($aday).mp4"    
    }
    else
    {
        Write-Warning "$aday has only $dailyvideos folder(s) which is less than 24 (day is not complete yet)."
    }
    

}


cd E:\camera\xiaomi_camera_videos\788b2ab6a8c1\