# Verification & Unit Testing for SubDL Filename Extraction and Match Scoring
# Simulates the regex and parsing logic implemented in SubDL.as

function ParseMediaMetadata([string]$fullPath) {
    # 1. Strip path and extension
    $fileName = Split-Path $fullPath -Leaf
    $rawBase = [System.IO.Path]::GetFileNameWithoutExtension($fileName)

    $season = 0
    $episode = 0
    $year = 0
    $isTV = $false

    # 2. TV pattern: S##E## or ##x##
    if ($rawBase -match '[sS]([0-9]{1,2})[eE]([0-9]{1,2})') {
        $season = [int]$matches[1]
        $episode = [int]$matches[2]
        $isTV = $true
    } elseif ($rawBase -match '(?:^|[^0-9])([0-9]{1,2})x([0-9]{1,2})') {
        $season = [int]$matches[1]
        $episode = [int]$matches[2]
        $isTV = $true
    }

    # 3. 4-digit Year (1920 - 2099)
    if ($rawBase -match '(?:^|[^0-9])(19[2-9][0-9]|20[0-3][0-9])(?:[^0-9]|$)') {
        $year = [int]$matches[1]
    }

    # 4. Extract Title portion
    $titleCandidate = ""
    if ($isTV) {
        if ($rawBase -match '^(.*?)[sS][0-9]{1,2}[eE][0-9]{1,2}') {
            $titleCandidate = $matches[1]
        } elseif ($rawBase -match '^(.*?)[0-9]{1,2}x[0-9]{1,2}') {
            $titleCandidate = $matches[1]
        }
    } elseif ($year -gt 0) {
        if ($rawBase -match '^(.*?)(?:19[2-9][0-9]|20[0-3][0-9])') {
            $titleCandidate = $matches[1]
        }
    }

    if ([string]::IsNullOrWhiteSpace($titleCandidate)) {
        $titleCandidate = $rawBase
    }

    # Normalize Title
    $titleCandidate = $titleCandidate -replace '[\._\-\(\)\[\]]', ' '
    $cleanTitle = $titleCandidate.Trim() -replace '\s+', ' '

    return [PSCustomObject]@{
        RawName    = $rawBase
        CleanTitle = $cleanTitle
        Year       = $year
        Season     = $season
        Episode    = $episode
        IsTV       = $isTV
    }
}

function ComputeMatchScore([string]$rawFileName, [string]$releaseName) {
    $f1 = $rawFileName.ToLower()
    $f2 = $releaseName.ToLower()

    if ([string]::IsNullOrEmpty($f1) -or [string]::IsNullOrEmpty($f2)) { return 0 }
    if ($f1 -eq $f2) { return 100 }

    $score = 40
    $tags = @(
        "bluray", "bdrip", "brrip", "web-dl", "webrip", "hdrip", "hdtv",
        "2160p", "1080p", "720p", "480p",
        "x264", "x265", "hevc", "avc", "10bit",
        "dts", "atmos", "ac3", "aac",
        "sparks", "rarbg", "yify", "yts", "geckos", "amiable", "flame", "surcode"
    )

    foreach ($tag in $tags) {
        $inF1 = $f1.Contains($tag)
        $inF2 = $f2.Contains($tag)
        if ($inF1 -and $inF2) { $score += 10 }
        elseif ($inF1 -ne $inF2) { $score -= 2 }
    }

    if ($score -gt 98) { $score = 98 }
    if ($score -lt 10) { $score = 10 }
    return $score
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Running SubDL Media Parser & Scoring Unit Tests        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$testCases = @(
    @{
        Input = "D:\Movies\Inception (2010)\Inception.2010.1080p.BluRay.x264-SPARKS.mkv"
        ExpectedTitle = "Inception"
        ExpectedYear = 2010
        ExpectedIsTV = $false
        SampleRelease = "Inception.2010.1080p.BluRay.x264-SPARKS"
    },
    @{
        Input = "D:\Series\Breaking Bad\Season 01\Breaking.Bad.S01E05.720p.HDTV.x264.mkv"
        ExpectedTitle = "Breaking Bad"
        ExpectedSeason = 1
        ExpectedEpisode = 5
        ExpectedIsTV = $true
        SampleRelease = "Breaking.Bad.S01E05.720p.HDTV.x264"
    },
    @{
        Input = "C:\Downloads\Dune.Part.Two.2024.2160p.UHD.BluRay.x265-SURCODE.mkv"
        ExpectedTitle = "Dune Part Two"
        ExpectedYear = 2024
        ExpectedIsTV = $false
        SampleRelease = "Dune.Part.Two.2024.2160p.UHD.BluRay.x265-SURCODE"
    },
    @{
        Input = "Game.of.Thrones.4x02.The.Lion.and.the.Rose.1080p.WEB-DL.mkv"
        ExpectedTitle = "Game of Thrones"
        ExpectedSeason = 4
        ExpectedEpisode = 2
        ExpectedIsTV = $true
        SampleRelease = "Game.of.Thrones.S04E02.1080p.WEB-DL"
    },
    @{
        Input = "Oppenheimer.2023.IMAX.1080p.BluRay.DDP5.1.Atmos.x264.mkv"
        ExpectedTitle = "Oppenheimer"
        ExpectedYear = 2023
        ExpectedIsTV = $false
        SampleRelease = "Oppenheimer.2023.1080p.BluRay.x264"
    }
)

$passed = 0
$total = $testCases.Count

foreach ($tc in $testCases) {
    $res = ParseMediaMetadata $tc.Input
    $score = ComputeMatchScore $res.RawName $tc.SampleRelease

    $titleMatch = ($res.CleanTitle -eq $tc.ExpectedTitle)
    $typeMatch  = ($res.IsTV -eq $tc.ExpectedIsTV)
    $yearMatch  = (-not $tc.ContainsKey("ExpectedYear") -or $res.Year -eq $tc.ExpectedYear)
    $seMatch    = (-not $tc.ContainsKey("ExpectedSeason") -or ($res.Season -eq $tc.ExpectedSeason -and $res.Episode -eq $tc.ExpectedEpisode))

    if ($titleMatch -and $typeMatch -and $yearMatch -and $seMatch) {
        Write-Host "[PASS] $($res.CleanTitle) | TV: $($res.IsTV) | S:$($res.Season) E:$($res.Episode) Y:$($res.Year) | Match Score: $score%" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Input: $($tc.Input)" -ForegroundColor Red
        Write-Host "       Parsed: Title='$($res.CleanTitle)', TV=$($res.IsTV), Y=$($res.Year), S=$($res.Season), E=$($res.Episode)" -ForegroundColor Red
        Write-Host "       Expected: Title='$($tc.ExpectedTitle)', TV=$($tc.ExpectedIsTV), Y=$($tc.ExpectedYear), S=$($tc.ExpectedSeason), E=$($tc.ExpectedEpisode)" -ForegroundColor Red
    }
}

Write-Host ""
$color = if ($passed -eq $total) { "Green" } else { "Red" }
Write-Host "Result: $passed / $total tests passed." -ForegroundColor $color
