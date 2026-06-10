<#
    deploy-vietinsoft.ps1

    Trien khai repo private cuongvu300582-rgb/VietinsoftWork bang GitHub Deploy Key.

    Cach dung:
      - Chuot phai file nay > Run with PowerShell
      - Hoac chay:
        powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy-vietinsoft.ps1

    Hanh vi khi chay lai:
      - Neu deploy key da ton tai: dung lai key cu, khong tao key moi.
      - Neu repo da clone: chi cap nhat source moi nhat bang git pull.
      - Neu repo chua co: clone repo ve may.
#>

param(
    [string]$InstallPath,
    [switch]$ForceNewKey,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoOwner = "cuongvu300582-rgb"
$RepoName = "VietinsoftWork"
$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($InstallPath)) {
    $InstallPath = Join-Path $ScriptDir $RepoName
}
$DeployKeysUrl = "https://github.com/$RepoOwner/$RepoName/settings/keys"
$SshAlias = "github-$RepoOwner-$RepoName"
$CloneUrl = "git@${SshAlias}:${RepoOwner}/${RepoName}.git"
$SshDir = Join-Path $env:USERPROFILE ".ssh"
$KeyName = "vietinsoft_deploy_key"
$KeyPath = Join-Path $SshDir $KeyName
$PubKeyPath = "$KeyPath.pub"
$SshConfigPath = Join-Path $SshDir "config"

function Write-Step($Text) {
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Write-OK($Text) {
    Write-Host "    OK: $Text" -ForegroundColor Green
}

function Write-Warn($Text) {
    Write-Host "    ! $Text" -ForegroundColor Yellow
}

function Write-Err($Text) {
    Write-Host "    X $Text" -ForegroundColor Red
}

function Pause-AndExit([int]$Code = 0) {
    if ($NoPause) {
        exit $Code
    }

    Write-Host ""
    if ($Code -ne 0) {
        Write-Host "Co loi xay ra. Xem thong tin ben tren." -ForegroundColor Red
    }
    Write-Host "Nhan Enter de dong cua so..." -ForegroundColor Yellow
    Read-Host | Out-Null
    exit $Code
}

function Test-CommandExists([string]$Command) {
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    return $null -ne $cmd
}

function Assert-RequiredCommand([string]$Command, [string]$InstallHint, [string[]]$VersionArgs = @("--version")) {
    if (Test-CommandExists $Command) {
        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $version = & $Command @VersionArgs 2>&1 | Select-Object -First 1
        } finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }
        Write-OK "$Command da san sang: $version"
        return
    }

    Write-Err "Khong tim thay lenh '$Command'."
    Write-Host "    $InstallHint" -ForegroundColor Yellow
    Pause-AndExit 1
}

function New-DeployKeyIfNeeded {
    if (-not (Test-Path $SshDir)) {
        New-Item -ItemType Directory -Path $SshDir -Force | Out-Null
        Write-OK "Da tao thu muc $SshDir"
    }

    if ($ForceNewKey -and (Test-Path $KeyPath)) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Move-Item -LiteralPath $KeyPath -Destination "$KeyPath.backup-$stamp" -Force
        if (Test-Path $PubKeyPath) {
            Move-Item -LiteralPath $PubKeyPath -Destination "$PubKeyPath.backup-$stamp" -Force
        }
        Write-Warn "Da backup key cu do dung -ForceNewKey."
    }

    if ((Test-Path $KeyPath) -and (Test-Path $PubKeyPath)) {
        Write-OK "Deploy key da ton tai, se dung lai: $KeyPath"
        return
    }

    if ((Test-Path $KeyPath) -and (-not (Test-Path $PubKeyPath))) {
        Write-Warn "Thieu public key, dang tao lai tu private key."
        & ssh-keygen -y -f $KeyPath | Set-Content -Path $PubKeyPath -Encoding ascii
        Write-OK "Da tao lai public key: $PubKeyPath"
        return
    }

    if ((-not (Test-Path $KeyPath)) -and (Test-Path $PubKeyPath)) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Move-Item -LiteralPath $PubKeyPath -Destination "$PubKeyPath.orphan-$stamp" -Force
        Write-Warn "Da doi ten public key cu vi khong co private key tuong ung."
    }

    $comment = "deploy-$RepoOwner-$RepoName-$env:COMPUTERNAME"
    & ssh-keygen -t ed25519 -C $comment -f $KeyPath -N '""' | Out-Null

    if ((Test-Path $KeyPath) -and (Test-Path $PubKeyPath)) {
        Write-OK "Da tao deploy key moi: $KeyPath"
    } else {
        Write-Err "Tao deploy key that bai."
        Pause-AndExit 1
    }
}

function Set-SshConfigHost {
    $newBlock = @(
        "# Deploy key for $RepoOwner/$RepoName",
        "Host $SshAlias",
        "    HostName github.com",
        "    User git",
        "    IdentityFile $KeyPath",
        "    IdentitiesOnly yes",
        "    StrictHostKeyChecking accept-new"
    )

    $lines = @()
    if (Test-Path $SshConfigPath) {
        $lines = @(Get-Content -Path $SshConfigPath)
    }

    $output = New-Object System.Collections.Generic.List[string]
    $found = $false
    $i = 0

    while ($i -lt $lines.Count) {
        if ($lines[$i] -match "^\s*Host\s+$([regex]::Escape($SshAlias))\s*$") {
            $found = $true
            if (($output.Count -gt 0) -and ($output[$output.Count - 1] -match "^\s*# Deploy key for $([regex]::Escape($RepoOwner))/$([regex]::Escape($RepoName))\s*$")) {
                $output.RemoveAt($output.Count - 1)
            }
            foreach ($line in $newBlock) {
                $output.Add($line)
            }
            $i++
            while (($i -lt $lines.Count) -and ($lines[$i] -notmatch "^\s*Host\s+")) {
                $i++
            }
            continue
        }

        $output.Add($lines[$i])
        $i++
    }

    if (-not $found) {
        if (($output.Count -gt 0) -and ($output[$output.Count - 1].Trim() -ne "")) {
            $output.Add("")
        }
        foreach ($line in $newBlock) {
            $output.Add($line)
        }
    }

    if (Test-Path $SshConfigPath) {
        Copy-Item -LiteralPath $SshConfigPath -Destination "$SshConfigPath.backup" -Force
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($SshConfigPath, $output, $utf8NoBom)
    Write-OK "Da cau hinh SSH alias: $SshAlias"
}

function Copy-PublicKeyAndOpenGitHub {
    $pubKey = (Get-Content -Path $PubKeyPath -Raw).Trim()
    $pubKey | Set-Clipboard

    Write-Host ""
    Write-Host "Public key da duoc copy vao clipboard:" -ForegroundColor Yellow
    Write-Host $pubKey -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Hay them key tren GitHub Deploy keys:" -ForegroundColor Yellow
    Write-Host "    $DeployKeysUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Thong tin nen dien:" -ForegroundColor Yellow
    Write-Host "    Title: $env:COMPUTERNAME - $RepoName" -ForegroundColor White
    Write-Host "    Key:   Ctrl+V" -ForegroundColor White
    Write-Host "    Allow write access: bo tick neu chi can pull/clone" -ForegroundColor White

    Start-Process $DeployKeysUrl
}

function Test-DeployKeyAccess {
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = & ssh -o BatchMode=yes -o ConnectTimeout=10 -T $SshAlias 2>&1
        $text = ($result | Out-String).Trim()
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    if ($text -match "successfully authenticated" -or $text -match "Hi $([regex]::Escape($RepoOwner))/$([regex]::Escape($RepoName))") {
        Write-OK "GitHub da nhan deploy key."
        return $true
    }

    Write-Warn "Chua ket noi duoc GitHub bang deploy key."
    if ($text) {
        Write-Host "    $text" -ForegroundColor DarkGray
    }
    return $false
}

function Wait-UntilDeployKeyIsReady {
    if (Test-DeployKeyAccess) {
        return
    }

    Copy-PublicKeyAndOpenGitHub

    while ($true) {
        Write-Host ""
        Read-Host "Sau khi da them deploy key tren GitHub, nhan Enter de kiem tra lai" | Out-Null

        if (Test-DeployKeyAccess) {
            return
        }

        $answer = Read-Host "Thu lai tiep? (Y/n)"
        if ($answer -eq "n" -or $answer -eq "N") {
            Write-Err "Dung lai vi deploy key chua duoc GitHub chap nhan."
            Pause-AndExit 1
        }
    }
}

function Get-CurrentBranch {
    $branch = (& git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $branch) {
        return $null
    }
    return $branch
}

function Sync-Repository {
    if (Test-Path $InstallPath) {
        if (-not (Test-Path (Join-Path $InstallPath ".git"))) {
            Write-Err "Thu muc da ton tai nhung khong phai Git repo: $InstallPath"
            Write-Host "    Hay doi ten/xoa thu muc nay, hoac chay lai voi -InstallPath duong_dan_khac." -ForegroundColor Yellow
            Pause-AndExit 1
        }

        Write-OK "Repo da ton tai, se cap nhat source moi nhat."
        Push-Location $InstallPath
        try {
            & git remote set-url origin $CloneUrl
            & git config pull.rebase true

            $branch = Get-CurrentBranch
            if (-not $branch -or $branch -eq "HEAD") {
                Write-Err "Repo dang o trang thai detached HEAD, khong tu dong pull."
                Pause-AndExit 1
            }

            & git pull --rebase --autostash origin $branch
            if ($LASTEXITCODE -ne 0) {
                Write-Err "git pull that bai."
                Pause-AndExit 1
            }

            Write-OK "Da cap nhat source moi nhat tren branch $branch."
            & git status --short --branch
        } finally {
            Pop-Location
        }
        return
    }

    $parent = Split-Path -Parent $InstallPath
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Write-OK "Repo chua co, bat dau clone."
    & git clone $CloneUrl $InstallPath
    if ($LASTEXITCODE -ne 0) {
        Write-Err "git clone that bai."
        Pause-AndExit 1
    }

    Push-Location $InstallPath
    try {
        & git remote set-url origin $CloneUrl
        & git config pull.rebase true
        Write-OK "Clone thanh cong."
        & git status --short --branch
    } finally {
        Pop-Location
    }
}

try {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host "  DEPLOY VIETINSOFT WORK" -ForegroundColor Magenta
    Write-Host "  GitHub private repo qua Deploy Key" -ForegroundColor Magenta
    Write-Host "============================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Repository : $RepoOwner/$RepoName"
    Write-Host "Install tai: $InstallPath"
    Write-Host "Key path   : $KeyPath"

    Write-Step "Kiem tra Git va SSH"
    Assert-RequiredCommand "git" "Cai Git for Windows: https://git-scm.com/download/win"
    Assert-RequiredCommand "ssh" "Cai OpenSSH Client trong Windows Optional Features." @("-V")

    Write-Step "Kiem tra hoac tao deploy key"
    New-DeployKeyIfNeeded

    Write-Step "Cau hinh SSH"
    Set-SshConfigHost

    Write-Step "Kiem tra deploy key tren GitHub"
    Wait-UntilDeployKeyIsReady

    Write-Step "Clone hoac pull source code"
    Sync-Repository

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  HOAN TAT" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "Du an tai: $InstallPath" -ForegroundColor Cyan
    Write-Host "Cap nhat lan sau: chay lai file nay, script se chi git pull neu repo da ton tai." -ForegroundColor Cyan
    Pause-AndExit 0
} catch {
    Write-Host ""
    Write-Err "Loi: $($_.Exception.Message)"
    if ($_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    Pause-AndExit 1
}
