Param (
    [Parameter(Mandatory=$false)][string]$vault
)

Function Get-OpenFileName
{
    param([string]$initialDirectory,[string]$Filter)

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.initialDirectory = $initialDirectory
    $dialog.filter = $Filter
    $dialog.ShowDialog() | Out-Null
    $dialog.filename
    
}

if (-Not $vault) {
    $vault = Get-OpenFileName -Filter "XML (*.xml)| *.xml"
}
[XML]$vaultxml = Get-Content $vault


function Get-decodedHex {
    Param(
        [string]$string
    )
    $ret = ""
    if ($string) {
        $code = $string.Substring(0,2)
        try {
            $c = [char]([convert]::toInt16($code,16))
        }
        catch {
            return $null
        }
        [string]$ret = $c + (Get-DecodedHex -string $string.Substring(2))
    }
    $ret
}

function Get-ChildNodes {
Param (
    [System.Xml.XmlElement]$node,
    [int]$lvl
)
    $childNodes = $null
    $nodelvl = "`t"*$lvl
    $Anodelvl = "`t"*($lvl+1)
    $nodeStr = "$($nodelvl)NODE: $($node.Name)`n"
    $ChildNodes = $null
    $node.ChildNodes | Foreach-Object {
        if ($_.HasChildNodes) {
            $ChildNodes += Get-ChildNodes -node $_ -lvl ($lvl + 1)
        }
    }
    $nodestr += "$($Anodelvl)ATTRIBUTES:`n"
    $node.Attributes.GetEnumerator() | Where-Object { $_.Name -match "^(name|url|u|p|domain)$" } | Foreach-Object {
        $attrib = Get-DecodedHex($_.Value)
        if (-Not $attrib) {
            $attrib = $_.Value
        }
        $nodeStr += "$($Anodelvl)$($_.Name): $($attrib)`n"
    }
    $nodeStr += $childNodes
    $nodeStr
}

Get-ChildNodes -node $vaultXML.response.accounts -lvl 0
