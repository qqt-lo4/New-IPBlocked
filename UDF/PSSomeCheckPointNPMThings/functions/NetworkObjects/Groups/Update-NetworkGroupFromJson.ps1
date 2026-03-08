function Update-NetworkGroupFromJson {
    Param(
        [AllowNull()]
        [object]$ManagementInfo,
        [string]$JsonPath,
        [string]$XpathFilter,
        [Parameter(Mandatory)]
        [string]$Group
    )
    Begin {
        $oMgmtInfo = Get-ManagementFromCache -Management $ManagementInfo
        $oGroup = Get-NetworkGroup -ManagementInfo asfwstago -name $Group
        $sJsonPath = if ($JsonPath) {
            $JsonPath
        } else {
            Get-ObjectTagValue -ManagementInfo $oMgmtInfo -Object $oGroup -TagName "JsonPath"
        }
        if ($null -eq $sJsonPath) {
            throw "Json not provided or not found in group"
        }
        $sXpath = if ($XpathFilter) {
            $XpathFilter
        } else {
            Get-ObjectTagValue -ManagementInfo $oMgmtInfo -Object $oGroup -TagName "XpathFilter"
        }
        if ($null -eq $sXpath) {
            throw "Xpath filter not provided or not found in group"
        }
    }
    Process {
        $aRanges = (Get-FilteredJson -JsonPath $sJsonPath -XPath $sXpath) | Select-Object -Unique
        $aObjects = @()
        $iIndex = 0
        foreach ($sIP in $aRanges) {
            $iPercent = ($iIndex / $aRanges.Count) * 100
            Write-Progress -Activity "Getting Okta Objects" -Status "$sIP" -PercentComplete $iPercent
            Write-Verbose "$sIP in Okta ranges"
            $testObject = Test-CPObject -ManagementInfo $oMgmtInfo -Value $sIP
            if ($testObject) {
                Write-Verbose "$sIP object exists"
                $aObjects += $testObject[0]
            } else {
                Write-Verbose "$sIP needs to be created"
                $oNew = New-CPObject -ManagementInfo $oMgmtInfo -Value $sIP
                Write-Verbose "$sIP new object uid is $($oNew.uid)"
                $aObjects += $oNew
            }
            $iIndex += 1
        }
        Write-Verbose "Updating group $($oGroup.name) ($($oGroup.uid)) to all objects"
        Write-Progress -Activity "Getting Okta Objects" -Status "Updating group $($oGroup.name) ($($oGroup.uid)) to all objects" -PercentComplete 100
        Update-NetworkGroup -ManagementInfo $oMgmtInfo -uid $oGroup.uid -members $aObjects.uid
        Write-Progress -Activity "Getting Okta Objects" -Status "Operation ended" -PercentComplete 100 -Completed
    }
}