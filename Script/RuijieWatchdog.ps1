$AdapterAliasName="以太网"
$RuijiePath="D:\Program Files\锐捷网络\Ruijie Supplicant\8021x.exe"
$RuijieProcessName="8021x"
$CheckInterval=1


function Get-AdminStatus {
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-InternetStatus {
    param (
        [string]$ProfileName="Campus Network"
    )
    try {
        $NetworkStatus=Get-NetConnectionProfile -InterfaceAlias $ProfileName -ErrorAction Stop
        return $NetworkStatus.IPv4Connectivity.ToString().Equals("Internet")
    }
    catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException]{
        Write-Host "Network adapter alias name error!" -ForegroundColor Red
    }
}

function Get-RuijieStatus {
    param (
        [string]$ProcessName="8021x",
        [string]$FilePath="C:\Program Files\锐捷网络\Ruijie Supplicant\8021x.exe"
    )
    try {
        $RuijieProcess=Get-Process -Name $ProcessName -ErrorAction Stop
        Write-Host "锐捷正在运行" -ForegroundColor Green
    }
    catch [Microsoft.PowerShell.Commands.ProcessCommandException]{
        Write-Host "锐捷未运行，正在启动..." -NoNewline -ForegroundColor Yellow
        $RuijieProcess=Start-Network -FilePath $FilePath -ProcessName $RuijieProcessName
        Write-Host "锐捷正在运行" -ForegroundColor Green
    }
    return $RuijieProcess
}

function Start-Network {
    param (
        [string]$ProcessName="8021x",
        [string]$FilePath="C:\Program Files\锐捷网络\Ruijie Supplicant\8021x.exe",
        [string]$Arguments="-ssbero2008d -user"
    )
    try {
        Start-Process -FilePath $FilePath -ArgumentList $Arguments -ErrorAction Stop
        return Get-Process -Name $ProcessName
    }
    catch [System.InvalidOperationException]{
        Write-Host "Filepath error!" -ForegroundColor Red
    }
}

function Stop-Network {
    param (
        [string]$ProcessName="8021x"
    )
    try {
        Stop-Process -Name $ProcessName -ErrorAction Stop
    }
    catch [Microsoft.PowerShell.Commands.ProcessCommandException]{
        Write-Host "Process name error!" -ForegroundColor Red
    }
}

function Restart-Network {
    param (
        [string]$ProcessName="8021x",
        [string]$FilePath="C:\Program Files\锐捷网络\Ruijie Supplicant\8021x.exe",
        [string]$Arguments="-ssbero2008d -user"
    )
    Stop-Network -ProcessName $ProcessName
    Start-Sleep -Seconds 3
    $RuijieProcess=Start-Network -FilePath $FilePath -ArgumentList $Arguments -ProcessName $ProcessName
    return $RuijieProcess
}


$AdminStatus=Get-AdminStatus
if ( -not $AdminStatus) {
    Write-Host "管理员权限检查失败，请关闭此窗口并以管理员权限重新运行" -ForegroundColor Red
    return -1
}

$RuijieStatus=Get-RuijieStatus -ProcessName $RuijieProcessName -FilePath $RuijiePath

Write-Host "开始监控:" -ForegroundColor Green

do {
    $InternetStatus=Get-InternetStatus -ProfileName $AdapterAliasName
    if (-not $InternetStatus) {
        $CurrentTime=(Get-Date).ToString()
        Write-Host $CurrentTime "`t已断网" -NoNewline -ForegroundColor Red
        Write-Host "`t正在重连" -NoNewline -ForegroundColor Yellow
        $RuijieStatus=Restart-Network -ProcessName $RuijieProcessName -FilePath $RuijiePath
        Write-Host "`t已连接" -ForegroundColor Green
    }
    Start-Sleep -Seconds ($CheckInterval*15)
} while (1)