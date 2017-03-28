Set-StrictMode -Version Latest

# Helpers
function Get-FileFromUrl(
	[string] $URL,
	[string] $Output)
{
    Add-Type -AssemblyName "System.Net.Http"

    $client = New-Object System.Net.Http.HttpClient
    $request = New-Object System.Net.Http.HttpRequestMessage -ArgumentList @([System.Net.Http.HttpMethod]::Get, $URL)
    $responseMsg = $client.SendAsync($request)
    $responseMsg.Wait()

    if (!$responseMsg.IsCanceled)
    {
	$response = $responseMsg.Result
	if ($response.IsSuccessStatusCode)
	{
	    $downloadedFileStream = [System.IO.File]::Create($Output)
	    $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)
	    $copyStreamOp.Wait()
	    $downloadedFileStream.Close()
	    if ($copyStreamOp.Exception -ne $null)
	    {
		throw $copyStreamOp.Exception
	    }
	}
    }
}

# Disable automatic updates, windows firewall, and error reporting
#
# - They’ll just interrupt the builds later. 
# - We don't care about security since this isn't going to be Internet-facing. 
# - No ports will be accessible once the image is built.
New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -Value 1 -Force | Out-Null
new-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name Disabled -Value 1 -Force | Out-Null
new-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name DontShowUI -Value 1 -Force | Out-Null
netsh advfirewall set allprofiles state off

# Download buildlet
$url = "https://storage.googleapis.com/go-builder-data/buildlet-stage0.windows-amd64"
$builder_dir = "C:\golang"
$bootstrap_exe_path = "$builder_dir\bootstrap.exe"
mkdir $builder_dir
Get-FileFromUrl -URL $url -Output $bootstrap_exe_path

# Schedule buildlet to run on system startup
schtasks /Create /RU "System" /SC ONSTART /TR "cmd /k 'cd $builder_dir && $bootstrap_exe_path'" /TN GolangBuildlet

