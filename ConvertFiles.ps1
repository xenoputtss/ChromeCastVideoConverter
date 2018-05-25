param (
    [Parameter(Mandatory = $true)][string]$inputFolder
)

Get-ChildItem -File -Recurse -Filter '*.converted.*' $inputFolder | ForEach-Object {
    $fullName = $_.fullname
    Remove-Item $fullName
}

Get-ChildItem -File -Recurse $inputFolder | Sort-Object | ForEach-Object { 
    $fullName = $_.fullname
    $cmdOutput = ffmpeg -i "$fullName" 2>&1

    $hasVideo = $cmdOutput|Select-String -Pattern "Video:" #is there a video stream
    $hasAudio = $cmdOutput|Select-String -Pattern "Audio:" #is there an audio stream
    #if this is a video, then attempt to
    if ($hasVideo -and $hasAudio) {
        $VideoCodec = "copy"
        $AudioCodec = "copy"

        
        #If not h264
        $Video = $cmdOutput|Select-String -Pattern "Video:"|Select-String -Pattern "h264"
        if (!$Video) {
            $VideoCodec = "libx264"
        }

        #if h264, but High 10, convert down
        $Video = $cmdOutput|Select-String -Pattern "Video:"|Select-String -Pattern "High 10"
        if ($Video) {
            $VideoCodec = "libx264"
        }
        
        #if audio isn't aac
        $Audio = $cmdOutput|Select-String -Pattern "Audio:"|Select-String -Pattern "aac"
        if (!$Audio) {
            $AudioCodec = "aac"
        }


        #If the file is already in the format we want, skip it
        "$VideoCodec $AudioCodec $fullName" #write filename to console
        if ($AudioCodec -ne "copy" -or $VideoCodec -ne "copy") {
            $newName = "$fullName.converted.avi"
            ffmpeg -i "$fullName" -y -f mp4 -acodec $AudioCodec -ab 192k -ac 2 -absf aac_adtstoasc -async 2  -vcodec $VideoCodec -vsync 0 -level 4.1 -qmax 22 -qmin 20 -x264opts no-cabac:ref=2 -threads 0 -loglevel warning $newName -v quiet -stats
            Remove-Item -LiteralPath "$fullName"
            Rename-Item -LiteralPath "$newName" "$fullName"
        }
    }
    else {
        # "Deleting $fullName"
        # #get rid of non-video files from the video folder
        "deleteing $fullName" 
        Remove-Item -Path "$fullName"
    }
}