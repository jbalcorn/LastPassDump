Param (
    [Parameter(Mandatory = $false)][string]$vault,
    [Parameter(Mandatory = $false)][switch]$textOut,
    [Parameter(Mandatory = $false)][switch]$objOut
)

# Make sure the default is the original action
if (-Not ($textOut -or $objOut)) {
    $textOut = $true
}

Function Get-OpenFileName {
    param([string]$initialDirectory, [string]$Filter)

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.initialDirectory = $initialDirectory
    $dialog.filter = $Filter
    $dialog.ShowDialog() | Out-Null
    $dialog.filename
    
}
if (-Not $in) {
    if (-Not $vault) {
        $vault = Get-OpenFileName -Filter "XML (*.xml)| *.xml"
    }
    [XML]$vaultxml = Get-Content $vault
}
function Get-decodedHex {
    Param(
        [string]$string
    )
    $nonASCII = "[^\x20-\x7E]"
    $ret = $null
    if ($string -and $string.Length -gt 1) {
        $code = $string.Substring(0, 2)
        try {
            $c = [char]([convert]::toInt16($code, 16))
        }
        catch {
            throw "Not a Hex ASCII Character"
        }
        if ($c -cmatch $nonASCII) {
            throw "Non-ASCII Characters"
        }
        $ret = [string]($c + (Get-DecodedHex -string $string.Substring(2))) 
            
    }
    $ret
}

function Get-DecodedLPObj {
    Param (
        [System.Xml.XmlElement]$node
    )
    $nodeObj = New-Object -TypeName PSObject -Property @{
        NodeName = $node.ToString()
    }
    $node.Attributes.GetEnumerator() | Foreach-Object {
        if ($_.Value) {
            $nodeObj | Add-Member -MemberType NoteProperty -Name "$($_.Name)" -Value $_.Value
            try {
                $attrib = Get-DecodedHex($_.Value)
            }
            catch {
                $attrib = $null
            }
            if ($attrib) {
                $nodeObj | Add-Member -MemberType NoteProperty -Name "$($_.Name)Decoded" -Value $attrib
            }
        }
    }
    if ($node.HasChildNodes) {
        $nodeNames = $node.ChildNodes | Foreach-Object { $_.ToString() } | Sort-Object -Unique
        foreach ($name in $nodeNames) {
            $ChildNodesList = $node.GetElementsByTagName($name)
            if ($ChildNodesList.count -gt 1) {
                $nodeObj | Add-Member -NotePropertyMembers @{ $name = @() }
                $ChildNodesList.GetEnumerator() | Foreach-Object {
                    $nodeObj.$name += Get-DecodedLPObj -node $_
                }
            }
            else {
                $ChildObj = Get-DecodedLPObj -node $ChildNodesList.Item(0)
                $nodeObj | Add-Member -NotePropertyMembers @{ $name = $childObj }
            }
        }
    }
    $nodeObj
}
    
function Get-NodesAsText {
    Param (
        [PSObject]$node,
        [int]$lvl
    )
    $tabs = "`t" * $lvl
    $nodeStr = "$($tabs)NODE: $($node.ToString())`n"
    $node.Attributes.GetEnumerator() | Foreach-Object {
        if ($_.Value) {
            $nodeStr += "$($tabs)`t$($_.Name): $($_.Value)`n"
            try {
                $attrib = Get-DecodedHex($_.Value)
                
            }
            catch {
                $attrib = $null
            }
            if ($attrib) {
                $nodeStr += "$($tabs)`t$($_.Name) (Decoded): $($attrib)`n"
            }
        }
    }
    $node.ChildNodes | Foreach-Object {
        $nodeStr += Get-NodesAsText -node $_ -lvl ($lvl + 1)
    }
    $nodeStr
}

if ($objOut) {
    $vaultObj = New-Object -Typename PSObject -Property @{
        NodeName = 'Vault'
    }
    $nodeNames = $vaultxml.response.ChildNodes | Foreach-Object { $_.ToString() } | Sort-Object -Unique
    foreach ($name in $nodeNames) {
        $ChildNodesList = $vaultxml.response.GetElementsByTagName($name)
        if ($ChildNodesList.count -gt 1) {
            $vaultObj | Add-Member -NotePropertyMembers @{ $name = @() }
            $ChildNodesList.GetEnumerator() | Foreach-Object {
                $vaultObj.$name += Get-DecodedLPObj -node $_
            }
        }
        else {
            $ChildObj = Get-DecodedLPObj -node $ChildNodesList.Item(0)
            $vaultObj | Add-Member -NotePropertyMembers @{ $name = $childObj }
        }
    }
}
$VaultAsString = Get-NodesAsText -node $vaultxml.response -lvl 0

if ($ObjOut) {
    $vaultObj | Add-Member -NotePropertyName "VaultAsString" -NotePropertyValue $vaultAsString
    $vaultObj
}
else {
    $VaultAsString
}