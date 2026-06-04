[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

$sshDir = "$env:USERPROFILE\.ssh"
$keyPath = "$sshDir\vietinsoftwork_deploy_key"
$configPath = "$sshDir\config"

Write-Host "=== Bắt đầu thiết lập môi trường Deploy ===" -ForegroundColor Green

# 1. Tạo thư mục .ssh nếu chưa có
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
    Write-Host "Đã tạo thư mục $sshDir" -ForegroundColor Cyan
}

# 2. Tạo SSH Key
if (-not (Test-Path $keyPath)) {
    Write-Host "Đang tạo SSH key mới..." -ForegroundColor Cyan
    # Sử dụng cmd.exe để tránh các vấn đề parse string trống ở PowerShell
    cmd.exe /c "ssh-keygen -q -t ed25519 -C ""deploy_vietinsoftwork"" -f ""$keyPath"" -N """""
    Write-Host "Đã tạo SSH key tại $keyPath" -ForegroundColor Cyan
} else {
    Write-Host "SSH key đã tồn tại ở $keyPath" -ForegroundColor Yellow
}

# 3. Cấu hình SSH config
$configEntry = @"

Host github.com-vietinsoftwork
  HostName github.com
  User git
  IdentityFile $keyPath
"@

if (Test-Path $configPath) {
    $currentConfig = Get-Content $configPath -Raw
    if ($currentConfig -notmatch "Host github.com-vietinsoftwork") {
        Add-Content -Path $configPath -Value $configEntry
        Write-Host "Đã thêm cấu hình vào file $configPath" -ForegroundColor Cyan
    } else {
        Write-Host "Cấu hình SSH đã tồn tại trong $configPath" -ForegroundColor Yellow
    }
} else {
    Set-Content -Path $configPath -Value $configEntry
    Write-Host "Đã tạo mới file $configPath" -ForegroundColor Cyan
}

# 4. Hiển thị Public Key và chờ người dùng
$pubKey = Get-Content "$keyPath.pub"
Write-Host "`n========================================================" -ForegroundColor Magenta
Write-Host "BƯỚC QUAN TRỌNG:" -ForegroundColor Yellow
Write-Host "Vui lòng thêm Public Key sau vào Deploy Keys trên GitHub:" -ForegroundColor Green
Write-Host "URL: https://github.com/cuongvu300582-rgb/VietinsoftWork/settings/keys" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Magenta
Write-Host $pubKey -ForegroundColor White
Write-Host "`n========================================================" -ForegroundColor Magenta

Read-Host "Sau khi bạn đã THÊM THÀNH CÔNG Deploy Key trên GitHub, hãy nhấn Enter để tiếp tục clone dự án..."

# 5. Clone repository
$defaultTarget = Join-Path $env:USERPROFILE "VietinsoftWork"
$userTarget = Read-Host "`nNhập đường dẫn thư mục cài đặt dự án (Nhấn Enter để dùng mặc định: $defaultTarget)"
if ([string]::IsNullOrWhiteSpace($userTarget)) {
    $targetDir = $defaultTarget
} else {
    $targetDir = $userTarget
}

if (Test-Path $targetDir) {
    Write-Host "Thư mục $targetDir đã tồn tại. Vui lòng xóa nó trước nếu muốn clone lại." -ForegroundColor Red
    Read-Host "`nNhấn Enter để thoát..."
    exit
}

# Tìm git executable
$gitPath = "git"
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Program Files\Git\cmd\git.exe") {
        $gitPath = "C:\Program Files\Git\cmd\git.exe"
    } else {
        Write-Host "Không tìm thấy Git trên máy tính này. Vui lòng cài đặt Git trước!" -ForegroundColor Red
        Read-Host "`nNhấn Enter để thoát..."
        exit
    }
}

# Cài đặt biến môi trường để bỏ qua prompt StrictHostKeyChecking
$env:GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"

Write-Host "Đang tiến hành clone dự án vào $targetDir..." -ForegroundColor Cyan
& $gitPath clone git@github.com-vietinsoftwork:cuongvu300582-rgb/VietinsoftWork.git $targetDir

if ($LASTEXITCODE -eq 0 -or (Test-Path $targetDir)) {
    Write-Host "`nClone dự án THÀNH CÔNG vào $targetDir!" -ForegroundColor Green
    
    # Cài đặt npm dependencies nếu có package.json
    $packageJson = Join-Path $targetDir "package.json"
    if (Test-Path $packageJson) {
        Write-Host "Đang cài đặt các thư viện Node.js (npm install)..." -ForegroundColor Cyan
        $originalLocation = Get-Location
        Set-Location $targetDir
        try {
            npm install
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Cài đặt thư viện npm THÀNH CÔNG!" -ForegroundColor Green
            } else {
                Write-Host "Có lỗi xảy ra khi chạy npm install." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Không thể chạy npm install. Bạn đã cài đặt Node.js chưa?" -ForegroundColor Yellow
        } finally {
            Set-Location $originalLocation
        }
    }
} else {
    Write-Host "`nCó lỗi xảy ra trong quá trình clone. Vui lòng kiểm tra lại Deploy Key." -ForegroundColor Red
}

Read-Host "`nQuá trình cài đặt hoàn tất. Nhấn Enter để thoát..."
