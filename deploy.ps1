param([string]$token, [string]$owner, [string]$repo, [string]$localPath)

$apiBase = "https://api.github.com/repos/$owner/$repo/contents"
$tmpDir = "C:\Users\ABozhesko\AppData\Local\Temp\opencode"
if(-not (Test-Path $tmpDir)){ New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }
$bodyFile = Join-Path $tmpDir "body.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Upload-File($localFilePath, $remoteFilePath) {
    $bytes = [System.IO.File]::ReadAllBytes($localFilePath)
    $b64 = [Convert]::ToBase64String($bytes)
    $json = '{"message":"Add ' + $remoteFilePath + '","content":"' + $b64 + '","branch":"main"}'
    [System.IO.File]::WriteAllText($bodyFile, $json, $utf8NoBom)
    $url = "$apiBase/$remoteFilePath"
    Write-Output "Uploading: $remoteFilePath"
    $resp = & curl.exe -s -X PUT -H "Authorization: token $token" -H "Accept: application/vnd.github+json" -H "Content-Type: application/json" --data-binary "@$bodyFile" $url
    if($resp -match '"sha"'){ Write-Output "  OK" } else { Write-Output "  FAIL: $resp" }
}

$files = Get-ChildItem -Path $localPath -File -Recurse
foreach($f in $files) {
    $rel = $f.FullName.Substring($localPath.Length).Replace("\","/").TrimStart("/")
    Upload-File -localFilePath $f.FullName -remoteFilePath $rel
}
Write-Output "DONE"
