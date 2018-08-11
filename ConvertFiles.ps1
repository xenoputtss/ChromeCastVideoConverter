param (
    [Parameter(Mandatory = $true)][string]$inputFolder
)

# Clean up partially converted files.  
Get-ChildItem -File -Recurse -Filter '*.converted.*' $inputFolder | ForEach-Object {
    $fullName = $_.fullname
    Add-Content f:\DeletedFiles.txt "Converted - $fullName"
    Remove-Item $fullName
}

# Find All files and see if what we need to convert
Get-ChildItem -File -Recurse $inputFolder | Sort-Object Name | ForEach-Object {
    $fullName = $_.fullname
    $cmdOutput = ffmpeg -i "$fullName" 2>&1
    # "$cmdOutput"
    $hasVideo = $cmdOutput|Select-String -Pattern "Video:" -Quiet #is there a video stream
    $hasAudio = $cmdOutput|Select-String -Pattern "Audio:" -Quiet #is there an audio stream
    $videobitrate = $cmdOutput | Select-String -Pattern "\d,\s(?'bitrate'\d*)\skb\/s," -AllMatches | % {$_.matches.groups[1]} | %{$_.value} #video bitrate
    $videobitrate = [int]$videobitrate
    "$videobitrate"
    #if this is a video, then attempt to
    if ($hasVideo -and $hasAudio) {
        $VideoCodec = "copy"
        $AudioCodec = "copy"

        #we will need to reduce the bitrate
        if([int]($videobitrate) -gt 13000){
            $VideoCodec = "libx264 -profile:veryslow"
        }

        #If not h264
        $Video = $cmdOutput|Select-String -Pattern "Video:"|Select-String -Pattern "h264" -Quiet
        if (!$Video) {
            $VideoCodec = "libx264 -profile:veryslow"
        }

        #if h264, but High 10, convert down
        $Video = $cmdOutput|Select-String -Pattern "Video:"|Select-String -Pattern "High 10" -Quiet
        if ($Video) {
            "High 10 Video doesn't seem to rencode to a different format"
            $VideoCodec = "libx264 -profile:veryslow"
        }

        #if audio isn't aac
        $Audio = $cmdOutput|Select-String -Pattern "Audio:"|Select-String -Pattern "aac"
        if (!$Audio) {
            $AudioCodec = "aac"
        }


        #If the file is already in the format we want, skip it
        "$VideoCodec $AudioCodec $fullName" #write filename to console
        $newName = "$fullName.converted.avi"
        if ($AudioCodec -ne "copy" -or $VideoCodec -ne "copy") {
            "$Video"
            Add-Content f:\ConveringFiles.txt "$fullName"

            # ffmpeg -i "$fullName" -y -f mp4 -acodec $AudioCodec -ab 192k -ac 2 -absf aac_adtstoasc -async 2  -vcodec $VideoCodec -vsync 0 -level 4.1 -qmax 22 -qmin 20 -x264opts no-cabac:ref=2 -threads 0 -loglevel warning $newName -v quiet -stats
            ffmpeg.exe -y -nostats -i "$fullName" -strict experimental -f mp4 -c:v libx264 -profile:v high -level 4.1 -bufsize 13000 -maxrate 13000 -pix_fmt yuv420p -preset superfast -qp 20 -c:a aac -b:a 320k -af volume=3.0 -sn -movflags faststart $newName -v quiet -stats
            # level=4.2:ref=4:b-adapt=2:direct=auto:me=umh:subme=8:vbv-bufsize=13000:vbv-maxrate=13000:crf=21:rc-lookahead=50
            Remove-Item -LiteralPath "$fullName"
            Rename-Item -LiteralPath "$newName" "$fullName"
        }
    }
    else {
        # "Deleting $fullName"
        # #get rid of non-video files from the video folder
        Add-Content f:\DeletedFiles.txt "Non-Video $fullName"
        "deleteing $fullName" 
        Remove-Item -Path "$fullName"
    }
}
