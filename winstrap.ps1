# Helper functions
$port = new-Object System.IO.Ports.SerialPort COM1,9600,None,8,one
$port.open()
Function Write-SerialPort ([string] $message) {
    $port.WriteLine("winstrap.ps1: $($message)")
}

# Test output
Write-SerialPort "Hello World"
Get-Process | Out-File c:\test.txt

Set-StrictMode -Version Latest

#
# Disable automatic updates
#
# They’ll just interrupt the builds later. And we don't care about security since this isn't
# going to be Internet-facing. No ports will be accessible once the image is built.
#

Write-SerialPort "Disable Automatic Updates"
New-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1 -Force | Out-Null

# Disable error reporting
Write-SerialPort "Disable Error Reporting"
Disable-WindowsErrorReporting

# Disable the Windows firewall (GCE provides its own)
Write-SerialPort "Disable Windows Firewall"
netsh advfirewall set allprofiles state off

# Download buildlet
Add-Type -AssemblyName "System.Net.Http"
$url = "https://storage.googleapis.com/go-builder-data/buildlet-stage0.windows-amd64"
$builder_dir = "C:\golang"
$bootstrap_exe_path = "$builder_dir\bootstrap.exe"
mkdir $builder_dir

Write-SerialPort "Downloading buildlet boostrapping executable"
$client = New-Object System.Net.Http.HttpClient
$request = New-Object System.Net.Http.HttpRequestMessage -ArgumentList @([System.Net.Http.HttpMethod]::Get, $url)
$responseMsg = $client.SendAsync($request)
$responseMsg.Wait()

if (!$responseMsg.IsCanceled)
{
    $response = $responseMsg.Result
    if ($response.IsSuccessStatusCode)
    {
	$downloadedFileStream = [System.IO.FileStream]::new($bootstrap_exe_path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
	$copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
	$copyStreamOp.Wait()
	$downloadedFileStream.Close()
	if ($copyStreamOp.Exception -ne $null)
	{
	    throw $copyStreamOp.Exception
	}
    }
}

Write-SerialPort "Scheduling buildlet bootstrap to start on boot"
schtasks /Create /RU "System" /SC ONSTART /TR "cmd /k 'cd $builder_dir && $bootstrap_exe_path'" /TN GolangBuildlet

$port.Close()
