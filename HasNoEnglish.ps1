param (
    [Parameter(Mandatory = $true)][string]$inputFolder
)

# Find all files
Get-ChildItem -File -Recurse $inputFolder | Sort-Object | ForEach-Object { 
    $fullName = $_.fullname
    $cmdOutput = ffprobe -i "$fullName" 2>&1

    # "$cmdOutput"
    # $hasVideo = $cmdOutput|Select-String -Pattern "Video:" #is there a video stream
    $isEnglishAudio = $cmdOutput | Select-String -Pattern "\(eng\): Audio:" -Quiet #known english audio
    $isUnknownAudio = $cmdOutput | Select-String -Pattern "(\(und\): Audio:)" -Quiet #known 'unknown' audio
    $hasAudioLanguageTag = $cmdOutput | Select-String -Pattern "(\(\w*\):){1}(\s(Audio))" -Quiet #is there a standard language?

    if($isUnknownAudio){
        #so far, most videos with no labled audio track are english
        #this will require manual work if wrong
    }
    elseif (-Not $isEnglishAudio -and $hasAudioLanguageTag) {
        #we if there isn't an english track and there are other named audio tracks, its very very likely we don't have english audio
        Add-Content f:\DeletedFiles.txt "Missing English $fullName"
        # "Missing English $fullName"
        Remove-Item $fullName
    }
    elseif (-Not $isEnglishAudio ) {
        #the video doesn't use standard nameing conventions
        #this will require manual work if wrong
        "Unknown Language:  $fullName"
    }
}
