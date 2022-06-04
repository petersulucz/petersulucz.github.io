# VMDX to VHD conversion

You can easily convert a VMWare VMDX file to a Microsoft VHD file using the “Microsoft Virtual Machine Converter“. The Command ‘ConvertTo-MvmcVirtualHardDisk’ transforms the VMWare disk into a Hyper-V Compatible disk.

Once the Microsoft Virtual Machine Converter is installed, you can load the commandlets into a powershell session:

```powershell
Import-Module 'C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1'
```

Once you have that, a command like below will do the trick:

```powershell
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath 'D:\VM\CNC Windows 7 Professional\Windows 7 Pro
fessional-cl1.vmdk' -DestinationLiteralPath 'D:\VM\CNC Windows 7 Professional Hyper-v\Windows 7 Professional-cl1.vhd' -V
hdType DynamicHardDisk -VhdFormat Vhd
```

## Errors

Now, for the true purpose of this article. Sometimes, ‘ConvertTo-MvmcVirtualHardDisk’ will throw an error, because it can’t understand something in the descriptor of the .VMDX. An error like below…

```powershell
ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath 'D:\VM\CNC Windows 7 Professional\Windows 7 Pro
fessional-cl1.vmdk' -DestinationLiteralPath 'D:\VM\CNC Windows 7 Professional Hyper-v\Windows 7 Professional-cl1.vhd' -V
hdType DynamicHardDisk -VhdFormat Vhd
ConvertTo-MvmcVirtualHardDisk : The entry 1 is not a supported disk database entry for the descriptor.
At line:1 char:1
+ ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath 'D:\VM\CNC Windows 7 ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : WriteError: (Microsoft.Accel...nversionService:DriveConversionService) [ConvertTo-MvmcVi
   rtualHardDisk], VmdkDescriptorParseException
    + FullyQualifiedErrorId : DiskConversion,Microsoft.Accelerators.Mvmc.Cmdlet.Commands.ConvertToMvmcVirtualHardDiskCommand

ConvertTo-MvmcVirtualHardDisk : One or more errors occurred.
At line:1 char:1
+ ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath 'D:\VM\CNC Windows 7 ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : WriteError: (Microsoft.Accel...nversionService:DriveConversionService) [ConvertTo-MvmcVi
   rtualHardDisk], AggregateException
    + FullyQualifiedErrorId : DiskConversion,Microsoft.Accelerators.Mvmc.Cmdlet.Commands.ConvertToMvmcVirtualHardDiskCommand
```

Finding good instructions online for how to solve this were tough, and most included downloading another program. This script takes the VMDK file, and reads the 1024 byte file descriptor at offset 512, then writes it to a text file. It will open that file in notepad++, but you can use any editor you like. After editing the text file, save, and use the second half of the script to write it back into the VMDK. If the VMDK is very important to you, please make a copy, to make sure you can still access your data if something were to go wrong.

```powershell
# Open VM-ware disk, read 1024 bytes at position 512
$vmdkFileName = 'D:\VM\CNC Windows 7 Professional\Windows 7 Professional-cl1.vmdk'
$vmdkFileStream = [System.IO.File]::Open($vmdkFileName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
$vmdkFileStream.Position = 512

$bytes = [byte[]]::new(1024);
$vmdkFileStream.Read($bytes, 0, 1024)

# Write to a temp file
$tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetTempFileName())
$tempfile = [System.IO.File]::OpenWrite($tempPath)
$tempfile.Write($bytes, 0, 1024)
$tempfile.Dispose()

# Open the editor. Wait for exit doesn't always seem to work for npp...
# Use whichever edit you like, it needs to show text, and also helpful if it can show whitespace/control characters
$editor = Start-Process 'C:\Program Files\Notepad++\notepad++.exe' -ArgumentList $tempPath -PassThru -Wait
$editor.WaitForExit()

# TODO, change what is causing the problem in the opened file.
```

Now, an editor will open. You will see the file descriptor. The error message will describe which line in the file is causing the issue. Commenting (with a ‘#’) that line out of the file did the trick for me. Save, and run this to write the contents back into the VMDK.

For example, my error was “ConvertTo-MvmcVirtualHardDisk : The entry 1 is not a supported disk database entry for the descriptor.” So I commented out the line: db.toolsInstallType = “1”.

```powershell
# Read back the temp file
$tempfile = [System.IO.File]::OpenRead($tempPath)
$tempfile.Read($bytes, 0, 1024);
$tempfile.Dispose()

# Write back to the vmdk
$vmdkFileStream.Position = 512
$vmdkFileStream.Write($bytes, 0, 1024)

# Cleanup
$vmdkFileStream.Dispose();
del $tempPath
```

Then try the conversion again!. If the entry to change was ambiguous, and didnt work, you can run the same steps again to try different changes.