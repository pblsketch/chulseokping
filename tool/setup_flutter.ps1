# 출석핑 — Flutter SDK 설치 마무리 (Windows)
# 사용법: 일반 PowerShell에서
#   powershell -ExecutionPolicy Bypass -File tool\setup_flutter.ps1
# 동작: zip 완전 다운로드(이어받기) → SHA256 검증 → C:\dev\flutter 추출 → 사용자 PATH 등록 → flutter doctor
$ErrorActionPreference = "Stop"

$url  = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.4-stable.zip"
$zip  = "C:\dev\flutter_3.44.4-stable.zip"
$dest = "C:\dev"
$bin  = "C:\dev\flutter\bin"
$expectedSha = "8f2d6224fc6872d2f7f180de86cde989fcea3776efe0edf48a9aac2cd9be2b1b"
$targetBytes = 1899165696   # 1811 MiB

New-Item -ItemType Directory -Force -Path $dest | Out-Null

# 1) 완전 다운로드 (이 네트워크는 ~200MB에서 끊기므로 이어받기 반복; 진전 없으면 중단)
$maxAttempts = 60
$attempt = 0
$prevSize = -1
while (-not (Test-Path $zip) -or ((Get-Item $zip).Length -lt $targetBytes)) {
    $cur = if (Test-Path $zip) { (Get-Item $zip).Length } else { 0 }
    if ($cur -le $prevSize) { $attempt++ } else { $attempt = 0 }   # 진전 없을 때만 카운트
    if ($attempt -ge $maxAttempts) { throw "Download stalled: no progress after $maxAttempts attempts ($cur / $targetBytes bytes)." }
    $prevSize = $cur
    Write-Host ("Resuming download... {0:N0} / {1:N0} bytes" -f $cur, $targetBytes)
    & curl.exe -fL -C - --retry 10 --retry-all-errors --retry-delay 2 -o $zip $url
}
Write-Host "Download complete."

# 2) 무결성 검증
$sha = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
if ($sha -ne $expectedSha) { throw "SHA256 mismatch! got $sha" }
Write-Host "SHA256 OK."

# 3) 압축 해제 (Windows 기본 tar = 빠름)
if (-not (Test-Path "$bin\flutter.bat")) {
    Write-Host "Extracting (1~2min)..."
    & tar.exe -xf $zip -C $dest
} else { Write-Host "Already extracted." }

# 4) 사용자 PATH 등록 (새 터미널부터 적용)
$userPath = [Environment]::GetEnvironmentVariable("Path","User")
if ($userPath -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", ($userPath.TrimEnd(';') + ";" + $bin), "User")
    Write-Host "Added $bin to USER PATH. >>> Open a NEW terminal. <<<"
} else { Write-Host "PATH already has flutter bin." }

# 5) 점검
& "$bin\flutter.bat" --version
& "$bin\flutter.bat" doctor
Write-Host "Done. Android build needs: winget install Google.AndroidStudio"
