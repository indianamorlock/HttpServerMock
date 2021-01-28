# Use the following commands to bind/unbind SSL cert
# netsh http add sslcert ipport=0.0.0.0:443 certhash=3badca4f8d38a85269085aba598f0a8a51f057ae "appid={00112233-4455-6677-8899-AABBCCDDEEFF}"
# netsh http delete sslcert ipport=0.0.0.0:443 



function Blink-Message {
 param([String]$Message,[int]$Delay,[int]$Count,
       [ConsoleColor]$Color1,[ConsoleColor]$Color2)
    for($i = 0; $i -lt $Count; $i++) {
        Clear-Host
        $useColor = if( $i % 2 -eq 0 ) { $Color1 } else {$Color2 }
        Write-Host $Message -ForegroundColor $useColor
        Start-Sleep -Milliseconds $Delay
    }
}
Set-Alias bk Blink-Message


function Prep
{

	[cmdletbinding()]

	$httpPort = Read-Host -Prompt 'HTTP Listen TCP Port (Default is 80)'
	if ([string]::IsNullOrWhiteSpace($httpPort))
	{
		[int]$httpPort=80
		Write-Warning "Using default value. HTTP Listining on port: '$httpPort'"	
	}

	$httpsPort = Read-Host -Prompt 'HTTPS Listen TCP Port (Default is 443)'
	if ([string]::IsNullOrWhiteSpace($httpsPort))
	{
		[int]$httpsPort=443	
		Write-Warning "Using default value. HTTPS Listining on port: '$httpsPort'"
	}

	$httpCode = Read-Host -Prompt 'HTTP Status Code to be returned (Default is 200)'
	if ([string]::IsNullOrWhiteSpace($httpCode))
	{
		[int]$httpCodeInt=200
		[string]$httpCodeEnum = [System.Net.HttpStatusCode]$httpCodeInt
			Write-Warning "Using default value. HTTP Status Code will be: '$httpCodeInt-$httpCodeEnum'"
	}
	else
	{
		
		try
		{
			$httpCodeInt = [int][System.Net.HttpStatusCode]$httpCode
			[string]$httpCodeEnum = [System.Net.HttpStatusCode]$httpCodeInt
				Write-Warning "HTTP Status Code will be: '$httpCodeInt-$httpCodeEnum'"
		}
		catch [System.SystemException]
		{

			bk "Unknown HttpStatusCode entered... Please specify one of the following possible values:" -Delay 10 -Count 10 Red White
			Write-Output "" # Newline
			Write-Output "" # Newline				
			[System.Enum]::GetValues('System.Net.HttpStatusCode') | ForEach-Object -Process{
				[PSCustomObject]@{
				Name = $_ 
				Value = $_.value__
				}
			}
			Start-Sleep -Milliseconds 1000
			Write-Output "" # Newline
			exit
		}
	}
	$httpMessage = Read-Host -Prompt 'HTTP Response message to be returned (Default is "Every lil thing gonna be alright...")'
	if ([string]::IsNullOrWhiteSpace($httpMessage))
	{
		[string]$httpMessage="Every lil thing's gonna be alright..."
	}

	$HttpListener = New-Object System.Net.HttpListener
	$HttpListener.Prefixes.Add("http://+:$httpPort/")
	$HttpListener.Prefixes.Add("https://+:$httpsPort/")
	$HttpListener.Start()
	While ($HttpListener.IsListening) 
	{
		
		$HttpContext = $HttpListener.GetContext()
		$HttpRequest = $HttpContext.Request
		$RequestUrl = $HttpRequest.Url.OriginalString
		if ($HttpContext.Request.Url.LocalPath -eq '/kill')
		{ 
			$listener.Abort(); 
			break; 
		}
		Write-Warning "$RequestUrl"
		if($HttpRequest.HasEntityBody) {
		  $Reader = New-Object System.IO.StreamReader($HttpRequest.InputStream)
		  Write-Warning $Reader.ReadToEnd()
		}
		$HttpResponse = $HttpContext.Response
		$HttpResponse.Headers.Add("Content-Type","text/plain")
		$HttpResponse.StatusCode = $httpCodeInt
		$ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes("$httpMessage")
		$HttpResponse.ContentLength64 = $ResponseBuffer.Length
		$HttpResponse.OutputStream.Write($ResponseBuffer,0,$ResponseBuffer.Length)
		$HttpResponse.Close()
		Write-Output "" # Newline
		
	}
	$HttpListener.Stop()


}

function init
{
	try
	{
		prep
	}
	catch [System.SystemException]
	{
			bk "Thank you bye bye... " -Delay 10 -Count 10 Red White
		exit
	}
}

init