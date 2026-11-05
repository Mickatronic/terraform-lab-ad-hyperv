$isoOriginal = "C:\ISO\windows2025-en.iso"
$mount = Mount-DiskImage -ImagePath $isoOriginal -PassThru
$lettre = ($mount | Get-Volume).DriveLetter

$dossierTravail = "C:\tmp\win2025"
New-Item -ItemType Directory -Force $dossierTravail
Copy-Item "${lettre}:\*" $dossierTravail -Recurse -Force

Dismount-DiskImage -ImagePath $isoOriginal

Copy-Item "C:\VMS\terraform-lab-ad-hyperv\Demo\autounattend.xml" "$dossierTravail\autounattend.xml"

$oscdimg   = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
$isoFinale = "C:\VMS\terraform-lab-ad-hyperv\Demo\windows2025_en_unattend.iso"

& $oscdimg  -m   -o   -u2   -udfver102   -l"WS2025_UNATTEND"   -bootdata:"2#p0,e,b${dossierTravail}\boot\etfsboot.com#pEF,e,b${dossierTravail}\efi\microsoft\boot\efisys_noprompt.bin" `
  $dossierTravail `
  $isoFinale
