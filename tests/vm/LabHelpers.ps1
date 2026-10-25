# Lab-only helpers. Loading this file does not create VMs, disks or accounts.
function Assert-AtlasLabLocation {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Path)
    $base=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    $full=[IO.Path]::GetFullPath($Path)
    if(-not $full.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)){throw 'Lab path escapes the dedicated root.'}
    $parent=$full
    while(-not (Test-Path -LiteralPath $parent)){$parent=[IO.Path]::GetDirectoryName($parent);if(-not $parent){throw 'Lab parent not found.'}}
    $item=Get-Item -LiteralPath $parent -Force -ErrorAction Stop
    while($item){
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Lab paths cannot cross reparse points.'}
        $item=if($item.PSIsContainer){$item.Parent}else{$item.Directory}
    }
}

function New-AtlasLabAnswer {
    [CmdletBinding()]
    param([ValidateSet('Home','Pro','LTSC')][string]$Profile,[Parameter(Mandatory)][string]$ImageName,
        [Parameter(Mandatory)][string]$Password,[Parameter(Mandatory)][string]$ComputerName)
    if($ComputerName -cnotmatch '^ATLAS-[A-Z0-9-]{1,9}$'){throw 'Unexpected lab computer name.'}
    if($Password.Length -lt 20){throw 'Lab password must be randomly generated and at least 20 characters.'}
    $image=[Security.SecurityElement]::Escape($ImageName);$secret=[Security.SecurityElement]::Escape($Password)
    $locale=if($Profile -eq 'LTSC'){'en-US'}else{'es-MX'}
    # Public edition-selection defaults. Setup selection does NOT activate Windows
    # or grant a license. Never use a personal/OEM host key in a test VM.
    $setupKey=switch($Profile){
        Home{'YTMG3-N6DKC-DKB77-7M9GH-8HVX7'}
        Pro{'VK7JG-NPHTM-C97JM-9MPGT-3V66T'}
        LTSC{'KBN8V-HFGQ4-MGXVD-347P6-PDQGT'}
    }
    # Only Windows Setup INSIDE the new VM receives this disk configuration.
    # The host script never attaches physical disks or invokes disk formatting.
    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
 <settings pass="windowsPE">
  <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <SetupUILanguage><UILanguage>$locale</UILanguage></SetupUILanguage><InputLocale>$locale</InputLocale><SystemLocale>$locale</SystemLocale><UILanguage>$locale</UILanguage><UserLocale>$locale</UserLocale>
  </component>
  <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <DiskConfiguration><Disk wcm:action="add"><DiskID>0</DiskID><WillWipeDisk>true</WillWipeDisk><CreatePartitions>
    <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>260</Size></CreatePartition>
    <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
    <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
   </CreatePartitions><ModifyPartitions>
    <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
    <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>AtlasLab</Label><Letter>C</Letter></ModifyPartition>
   </ModifyPartitions></Disk><WillShowUI>OnError</WillShowUI></DiskConfiguration>
   <ImageInstall><OSImage><InstallFrom><MetaData wcm:action="add"><Key>/IMAGE/NAME</Key><Value>$image</Value></MetaData></InstallFrom><InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo><WillShowUI>OnError</WillShowUI></OSImage></ImageInstall>
   <UserData><AcceptEula>true</AcceptEula><FullName>Atlas QA</FullName><Organization>Atlas Lab</Organization><ProductKey><Key>$setupKey</Key><WillShowUI>Never</WillShowUI></ProductKey></UserData>
  </component>
 </settings>
 <settings pass="specialize"><component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><ComputerName>$ComputerName</ComputerName><TimeZone>SA Pacific Standard Time</TimeZone></component></settings>
 <settings pass="oobeSystem">
  <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"><InputLocale>$locale</InputLocale><SystemLocale>$locale</SystemLocale><UILanguage>$locale</UILanguage><UserLocale>$locale</UserLocale></component>
  <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
   <OOBE><HideEULAPage>true</HideEULAPage><HideOnlineAccountScreens>true</HideOnlineAccountScreens><HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE><ProtectYourPC>1</ProtectYourPC></OOBE>
   <UserAccounts><LocalAccounts><LocalAccount wcm:action="add"><Password><Value>$secret</Value><PlainText>true</PlainText></Password><Group>Administrators</Group><Name>AtlasLab</Name><DisplayName>Atlas QA</DisplayName></LocalAccount></LocalAccounts></UserAccounts>
   <AutoLogon><Password><Value>$secret</Value><PlainText>true</PlainText></Password><Username>AtlasLab</Username><Enabled>true</Enabled><LogonCount>1</LogonCount></AutoLogon>
  </component>
 </settings>
</unattend>
"@
}

function New-AtlasLabIso {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Directory,[Parameter(Mandatory)][string]$Destination)
    if(Test-Path -LiteralPath $Destination){throw 'Refusing to overwrite existing lab ISO.'}
    if(-not ('AtlasLabIsoStream' -as [type])){
        Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class AtlasLabIsoStream {
 public static void Save(object source, string destination) {
  var stream=(IStream)source; var buffer=new byte[1048576]; var count=Marshal.AllocHGlobal(4);
  try { using(var file=new FileStream(destination,FileMode.CreateNew,FileAccess.Write)) {
   for(;;){stream.Read(buffer,buffer.Length,count);var read=Marshal.ReadInt32(count);if(read==0)break;file.Write(buffer,0,read);}
  }} finally {Marshal.FreeHGlobal(count);}
 }
}
'@
    }
    $image=New-Object -ComObject IMAPI2FS.MsftFileSystemImage
    try{
        $image.FileSystemsToCreate=3;$image.VolumeName='ATLAS_AUTOINSTALL'
        $image.Root.AddTree($Directory,$false)
        $result=$image.CreateResultImage()
        [AtlasLabIsoStream]::Save($result.ImageStream,$Destination)
    }finally{[void][Runtime.InteropServices.Marshal]::ReleaseComObject($image)}
}
