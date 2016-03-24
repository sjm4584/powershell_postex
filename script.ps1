write-host "------ Power0wn -------" -ForegroundColor Red


# Name: remote_shell
# Purpose: allows the user to type commands 'interactively' on a host
function remote_shell {
	write-host "[+] shell options: "
	# read in options for interactive shell 
	write-host "<target>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	$target = Read-Host
	
	# creds are stored in creds.csv so let's deal with that bullshit now
	if (Test-Path "creds.csv") {
		# read from creds.csv. Sort by "good" crds.
		$data = Import-CSV "creds.csv" | Where-Object {$_.hostname -eq $target}
		if ($data -ne $NULL) {
			write-host "[+] Stored Credentials for: " -NoNewline
			write-host "$target" -ForegroundColor Magenta
			$data | select-object | sort-object -Property Rating -Descending | format-table -autosize 
		} else {
			write-host "[!] There are no stored credentials for this target." -ForegroundColor Gray
		}
	}

	write-host "<uname>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	$uname = Read-Host
	
	write-host "<passw>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	# read in as plaintext so we can show users creds. #Jank
	$passw_plain = Read-Host #-AsSecureString
	# convert to pscred type so we can make the $creds tuple #Secureteh
	$passw = $passw_plain | ConvertTo-SecureString -asPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential($uname, $passw)
	
	
	
	# After creds are read in, launch interactive shell using invoke-command. #Jank
	write-host ">>> " -NoNewline -ForegroundColor Green
	$command = Read-Host
	if ($command -eq 'run') {
		# Make a test connection to see if everything is right. If not catch it
		try {
			$SB = [scriptblock]::create("echo '[+] Connection Established'")
			Invoke-Command -ComputerName $target -Credential $creds -ScriptBlock $SB -ErrorAction Stop
			# change rating from 'bad' to 'good'
			($csv = Import-CSV 'creds.csv' -Delimiter ',') |foreach {
				if ($_.Hostname -eq $target -and $_.Username -eq $uname -and $_.Password -eq $passw_plain -and $_.Rating -eq "bad"){
					$_.rating = "good"
				}
			}
			$csv | Export-CSV 'creds.csv' -Delimiter ',' -NoType
		}
		catch {
			$ErrorMessage = $_.Exception.Message
			write-host "[+] $ErrorMessage" -ForegroundColor Red -BackgroundColor White
			# change 'good' to 'bad'
			($csv = Import-CSV 'creds.csv' -Delimiter ',') |foreach {
				if ($_.Hostname -eq $target -and $_.Username -eq $uname -and $_.Password -eq $passw_plain -and $_.Rating -eq "good"){
					$_.rating = "bad"
				}
			}
			$csv | Export-CSV 'creds.csv' -Delimiter ',' -NoType
			break
		}
		write-host "[$target]" -NoNewline -ForegroundColor Gray 
		write-host " ~$ " -NoNewline -ForegroundColor Green
		$command = Read-Host
		while ($command -ne 'quit-shell'){	
			$SB = [scriptblock]::create($command)
			Invoke-Command -ComputerName $target -Credential $creds -ScriptBlock $SB
			
			write-host "[$target]" -NoNewline -ForegroundColor Gray 
			write-host " ~$ " -NoNewline -ForegroundColor Green
			$command = Read-Host
		}
	}
}

# Name: rdp
# Purpose: establishes an RDP session to the victim using mstsc
function rdp {
	write-host "[+] RDP options: "
	# read in options for interactive shell 
	write-host "<target>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	$target = Read-Host
	
	# creds are stored in creds.csv so let's deal with that bullshit now
	if (Test-Path "creds.csv") {
		# because fuck you that's why powershell god damnit.
		$data = Import-CSV "creds.csv" | Where-Object {$_.hostname -eq $target}
		if ($data -ne $NULL) {
			write-host "[+] Stored Credentials for: " -NoNewline
			write-host "$target" -ForegroundColor Magenta
			$data | select-object | format-table -autosize
		} else {
			write-host "[!] There are no stored credentials for this target." -ForegroundColor Gray
		}
	}

	write-host "<uname>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	$uname = Read-Host
	
	write-host "<passw>" -NoNewline -ForegroundColor Yellow
	write-host " >>> " -NoNewline -ForegroundColor Green
	# read in as plaintext so we can show users creds. #Jank
	$passw_plain = Read-Host #-AsSecureString
	# convert to pscred type so we can make the $creds tuple #Secureteh
	$passw = $passw_plain | ConvertTo-SecureString -asPlainText -Force

	# establish RDP session using janky mstsc because powershell RDP module isn't default installed
	write-host "(run) >>> " -NoNewline -ForegroundColor Green
	$command = Read-Host
	if ($command -eq 'run') {
	
		try {
			cmdkey /generic:$target /user:$uname /pass:$passw
			mstsc /v:$target
			# change rating from 'bad' to 'good'
			($csv = Import-CSV 'creds.csv' -Delimiter ',') |foreach {
				if ($_.Hostname -eq $target -and $_.Username -eq $uname -and $_.Password -eq $passw_plain -and $_.Rating -eq "bad"){
					$_.rating = "good"
				}
			}
			$csv | Export-CSV 'creds.csv' -Delimiter ',' -NoType
		}
		catch {
			$ErrorMessage = $_.Exception.Message
			write-host "[+] $ErrorMessage" -ForegroundColor Red -BackgroundColor White
			# change 'good' to 'bad'
			($csv = Import-CSV 'creds.csv' -Delimiter ',') |foreach {
				if ($_.Hostname -eq $target -and $_.Username -eq $uname -and $_.Password -eq $passw_plain -and $_.Rating -eq "good"){
					$_.rating = "bad"
				}
			}
			$csv | Export-CSV 'creds.csv' -Delimiter ',' -NoType
			break
		}
	}
}


while ($true) {
	write-host "[+] What would you like to do?: "
	write-host "[+] remote_shell"
	write-host "[+] port_scan (NOT IMPLEMENTED"
	write-host "[+] rdp"

	$choice = Read-Host ">>> "
	
	if ($choice -eq "f_load_creds") {
		$file = Read-Host "[+] CSV file name: "
		
	}
	if ($choice -eq 'remote_shell') {
		echo "[1] ps-remote it is!"
		remote_shell
	}
	elseif ($choice -eq 'rdp'){
		echo "[2] rdp it is!"
		rdp
	} 
	else {
		break
	}
}
