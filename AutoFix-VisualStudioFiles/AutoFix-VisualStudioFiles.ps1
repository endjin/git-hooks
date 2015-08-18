<#
.SYNOPSIS

    Scans the solution folder (the parent of the .git folder) for all app.config, web.config and *.csproj files and
    auto-formats them to minimise the possibility of getting merge conflicts based on the ordering of elements
    within these files.
    N.B. Use of this script is entirely at your own risk. We shall not be liable for any damage which may result from using it.

.DESCRIPTION

    app.config & web.config files - sorts appSettings elements by key, in alphabetic order, sorts assemblyBinding.dependentAssembly 
    elements alphabetically based on the assemblyIdentity.name attribute
    .csproj files - sorts appSettings elements by key, in alphabetic order, sorts Reference, ProjectReference & Compile elements

.NOTES

    File Name  : AutoFix-VisualStudioFiles.ps1
    Author     : Howard van Rooijen
    Requires   : PowerShell v3

.LINK

#>

Function AutoFix-WebConfig([string] $rootDirectory)
{
    $files = Get-ChildItem -Path $rootDirectory -Filter web.config -Recurse

    return Scan-ConfigFiles($files)
}

Function AutoFix-AppConfig([string] $rootDirectory)
{
    $files = Get-ChildItem -Path $rootDirectory -Filter app.config -Recurse

    return Scan-ConfigFiles($files)
}

Function Scan-ConfigFiles([System.IO.FileInfo[]] $files)
{
    $modifiedfiles = @()

    foreach($file in $files)
    {
		Try
		{
			$original = [xml] (Get-Content $file.FullName)
			$workingCopy = $original.Clone()
		
			if($workingCopy.configuration.appSettings -ne $null -and $workingCopy.configuration.appSettings.ChildNodes.Count > 1) 
            {     
					$sorted = $workingCopy.configuration.appSettings.add | sort { [string]$_.key }
					$lastChild = $sorted[-1]
					$sorted[0..($sorted.Length-2)] | foreach {$workingCopy.configuration.appSettings.InsertBefore($_, $lastChild)} | Out-Null
			}
			
			if ($workingCopy.configuration.runtime.assemblyBinding -ne $null -and $workingCopy.configuration.runtime.assemblyBinding.ChildNodes.Count > 1){
					$sorted = $workingCopy.configuration.runtime.assemblyBinding.dependentAssembly | sort { [string]$_.assemblyIdentity.name }
					$lastChild = $sorted[-1]
					$sorted[0..($sorted.Length-2)] | foreach {$workingCopy.configuration.runtime.assemblyBinding.InsertBefore($_,$lastChild)} | Out-Null
			}

			$differencesCount = (Compare-Object -ReferenceObject (Select-Xml -Xml $original -XPath "//*") -DifferenceObject (Select-Xml -Xml $workingCopy -XPath "//*")).Length

			if ($differencesCount -ne 0)
			{
				$workingCopy.Save($file.FullName) | Out-Null
				$modifiedfiles += $file.FullName
			}
		
		}
		Catch
		{
			$ErrorMessage = $_.Exception.Message
			Write-Host "Scan-ConfigFiles::: Reorder error en: "  $file.FullName "=>>>" $ErrorMessage
		}
    }

    return $modifiedfiles
}

Function AutoFix-CsProj([string] $rootDirectory)
{
    $files = Get-ChildItem -Path $rootDirectory -Filter *.csproj -Recurse
    $modifiedfiles = @()

    foreach($file in $files)
    {
        $original = [xml] (Get-Content $file.FullName)
        $workingCopy = $original.Clone()

        foreach($itemGroup in $workingCopy.Project.ItemGroup)
        {
            # Sort the ItemGroup elements
            $sorted = $itemGroup.ChildNodes | sort Name, Include -Unique

            if ($itemGroup -isnot [System.String]) # skip empty ItemGroups
            {
                $itemGroup.RemoveAll() | Out-Null
 
                foreach($item in $sorted){
                    $itemGroup.AppendChild($item) | Out-Null
                }
            }
        }

        $differencesCount = (Compare-Object -ReferenceObject (Select-Xml -Xml $original -XPath "//*") -DifferenceObject (Select-Xml -Xml $workingCopy -XPath "//*")).Length

        if ($differencesCount -ne 0)
        {
            $workingCopy.Save($file.FullName) | Out-Null
            $modifiedfiles += $file.FullName
        }
    }

    return $modifiedfiles
}

$rootDirectory = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "\..\..\"

$exitCode = 0;

$changedfiles = @()
$changedfiles += AutoFix-AppConfig($rootDirectory)
$changedfiles += AutoFix-CsProj($rootDirectory)
$changedfiles += AutoFix-WebConfig($rootDirectory)

if ($changedfiles.Count -gt 0)
{
    Write-Host "=== endjin git hooks ==="
    Write-Host "The following files have been auto-formatted"
    Write-Host "to reduce the likelyhood of merge conflicts:"
    
    foreach($file in $changedfiles)
    {
        Write-Host $file
    }

    $exitCode = 1;
}

exit $exitcode
