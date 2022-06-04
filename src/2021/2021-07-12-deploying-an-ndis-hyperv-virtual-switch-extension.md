# Deploying an NDIS HyperV Virtual Switch Extension

Here are some instructions on how to deploy a NDIS virtual switch extension to a Hyper-V Virtual Switch. This will save you some headaches during the driver deployment and validation process. Of course, before doing any of this, make sure you have a test host set up in Test Mode. “bcdedit /set testsigning on” Then reboot.

First comes first, after creating a basic NDIS lightweight filter driver project, make sure that your INF file is configured correctly. Here is a basic example, which will create a modifying filter driver which build for x64, and attaches only to virtual switches.

```inf
;-------------------------------------------------------------------------
; basicndis.INF -- NDIS LightWeight Filter Driver
;-------------------------------------------------------------------------

[version]
; Do not change these values
Signature       = "$Windows NT$"
Class           = NetService
ClassGUID       = {4D36E974-E325-11CE-BFC1-08002BE10318}
Provider        = %Badflyer%
DriverVer       = 
CatalogFile     = basicndis.cat


[Manufacturer]
%Badflyer%=MSFT,NTx86,NTamd64,NTarm,NTarm64

; BADFLYER_basicndis can be used with netcfg.exe to install/uninstall the driver.
[MSFT.NTx86]
%basicndis_Desc%=Install, BADFLYER_basicndis

[MSFT.NTamd64]
%basicndis_Desc%=Install, BADFLYER_basicndis

[MSFT.NTarm]
%basicndis_Desc%=Install, BADFLYER_basicndis

[MSFT.NTarm64]
%basicndis_Desc%=Install, BADFLYER_basicndis

;-------------------------------------------------------------------------
; Installation Section
;-------------------------------------------------------------------------
[Install]
AddReg=Inst_Ndi
; All LWFs must include the 0x40000 bit (NCF_LW_FILTER).
Characteristics=0x40000

; This must be a random, unique value.
; FILTER_UNIQUE_NAME in filter.h must match this GUID identically.
; Both should have {curly braces}.
NetCfgInstanceId="{3ca735b3-e816-470b-905e-9d5097241c74}"

Copyfiles = basicndis.copyfiles.sys

[SourceDisksNames]
1=%basicndis_Desc%,"",,

[SourceDisksFiles]
basicndis.sys=1

[DestinationDirs]
DefaultDestDir=12
basicndis.copyfiles.sys=12

[basicndis.copyfiles.sys]
basicndis.sys,,,2


;-------------------------------------------------------------------------
; Ndi installation support
;-------------------------------------------------------------------------
[Inst_Ndi]
HKR, Ndi,Service,,"basicndis"
HKR, Ndi,CoServices,0x00010000,"basicndis"
HKR, Ndi,HelpText,,%basicndis_HelpText%

HKR, Ndi,FilterClass,, "ms_switch_filter"
; TODO: Specify whether you have a Modifying or Monitoring filter.
; For a Monitoring filter, use this:
;     HKR, Ndi,FilterType,0x00010001, 1 ; Monitoring filter
; For a Modifying filter, use this:
;     HKR, Ndi,FilterType,0x00010001, 2 ; Modifying filter
HKR, Ndi,FilterType,0x00010001,2
; Do not change these values. These are required for a vswitch filter driver.
HKR, Ndi\Interfaces,UpperRange,,"noupper"
HKR, Ndi\Interfaces,LowerRange,,"nolower"
; In order to work with the virtual switch, you must include "vmnetextension". 
; Can also include "ethernet" to work on regular network stacks.
HKR, Ndi\Interfaces, FilterMediaTypes,,"vmnetextension"
; TODO: Specify whether you have a Mandatory or Optional filter
; For a Mandatory filter, use this:
;     HKR, Ndi,FilterRunType,0x00010001, 1 ; Mandatory filter
; For an Optional filter, use this:
;     HKR, Ndi,FilterRunType,0x00010001, 2 ; Optional filter
; Optional filters will allow the network stack on continue working if the filter is not.
HKR, Ndi,FilterRunType,0x00010001, 2 ; Optional filter

;-------------------------------------------------------------------------
; Service installation support
;-------------------------------------------------------------------------
[Install.Services]
; 0x800 Means to start the service automatically after installation. Remove it if you do not want that.
AddService=basicndis,0x800,basicndis_Service_Inst

[basicndis_Service_Inst]
DisplayName     = %basicndis_Desc%
ServiceType     = 1 ;SERVICE_KERNEL_DRIVER
; Typically you will want your filter driver to start with SERVICE_SYSTEM_START.
; If it is an Optional filter, you may also use 3;SERVICE_DEMAND_START.
StartType       = 1 ;SERVICE_SYSTEM_START
ErrorControl    = 1 ;SERVICE_ERROR_NORMAL
ServiceBinary   = %12%\basicndis.sys
LoadOrderGroup  = NDIS
Description     = %basicndis_Desc%
AddReg          = NdisImPlatformBindingOptions.reg

[Install.Remove.Services]
; The SPSVCINST_STOPSERVICE flag instructs SCM to stop the NT service
; before uninstalling the driver.
DelService=basicndis,0x200 ; SPSVCINST_STOPSERVICE

[NdisImPlatformBindingOptions.reg]
; By default, when an LBFO team or Bridge is created, all filters will be
; unbound from the underlying members and bound to the TNic(s). This keyword
; allows a component to opt out of the default behavior
; To prevent binding this filter to the TNic(s):
;   HKR, Parameters, NdisImPlatformBindingOptions,0x00010001,1 ; Do not bind to TNic
; To prevent unbinding this filter from underlying members:
;   HKR, Parameters, NdisImPlatformBindingOptions,0x00010001,2 ; Do not unbind from Members
; To prevent both binding to TNic and unbinding from members:
;   HKR, Parameters, NdisImPlatformBindingOptions,0x00010001,3 ; Do not bind to TNic or unbind from Members
HKR, Parameters, NdisImPlatformBindingOptions,0x00010001,0 ; Subscribe to default behavior



[Strings]
; TODO: Customize these strings.
Badflyer = "badflyer" ;TODO: Replace with your manufacturer name
basicndis_Desc = "basicndis NDIS LightWeight Filter"
basicndis_HelpText = "basicndis NDIS LightWeight Filter"
```

The comments here are mostly from the NDIS lightweight filter template which comes with the Windows Driver Kit. Now you can install the driver onto a target computer. Assuming the target computer is a 64 bit machine.

```inf
; The important sections to note from the .info file:

; This specifies the x64 install, and we will need 'BADFLYER_basicndis' to install with netcfg
[MSFT.NTamd64]
%basicndis_Desc%=Install, BADFLYER_basicndis

; This specifies that this is a filtering extension
HKR, Ndi,FilterClass,, "ms_switch_filter"

; This specifies that we will bind to a virtual switch as an extension
HKR, Ndi\Interfaces, FilterMediaTypes,,"vmnetextension"

; 0x800 Automatically starts the driver after installation.
AddService=basicndis,0x800,basicndis_Service_Inst
```

1. Compile the project as x64
2. Copy the output to the target computer. (The target computer should bet in testmode “bcdedit /set testsigning on”). The output directory should contain atleast 3 files.
    - basicndis.cat
    - basicndis.inf
    - basicndis.sys
3. Use netcfg to install the driver. (instructions below)
4. Use powershell to enable the extension on the virtual switch (instructions below)

So, now that the files are copied over. You can use netcfg.exe to install the driver service. This will come by default on windows.

```powershell
#
# You can lookup the documentation for netcfg online, but here is basically what needs to happen:
# netcfg /l <path to inf file> /c S /i <driver installation name from inf>
#
# The driver installation name can be found/set in the .inf file in the platform configuration section.
# EX:  ; BADFLYER_basicndis can be used with netcfg.exe to install/uninstall the driver.
#        [MSFT.NTx86]
#        %basicndis_Desc%=Install, BADFLYER_basicndis
#
# Here is an example
netcfg /l C:\Users\Administrator\Desktop\basicndis\basicndis.inf /c S /i BADFLYER_basicndis
```

If all goes well, you will get a nice happy message about success. If it does not, you will get an error code. Logs for netcfg can be found under “C:\Windows\INF\setupapi.dev.log” aka “%SYSTEMROOT%\INF\setupapi.dev.log” and “%SYSTEMROOT%\INF\setupapi.app.log”.

Hopefully as is well, can you have gotten this far, you can enable the extension on the Hyper-V virtual switch. In this example, I have a VM Switch named “InternalSwitch”.

```powershell
PS C:\Users\Administrator> Get-VMSwitchExtension -VMSwitchName internalswitch | where { $_.Vendor -match 'badflyer' }


Id                  : 3CA735B3-E816-470B-905E-9D5097241C74
Name                : basicndis NDIS LightWeight Filter
Vendor              : badflyer
Version             : 23.54.47.252
ExtensionType       : Filter
ParentExtensionId   :
ParentExtensionName :
SwitchId            : 655c9bd4-0d5b-4322-8b39-1b9a58e0ce94
SwitchName          : InternalSwitch
Enabled             : False
Running             : True
CimSession          : CimSession: .
ComputerName        : WIN-7Q9KPM774O8
IsDeleted           : False
```

If you query for it, the driver is running, but is not enabled on the switch. But that’s an easy fix.

```powershell
Get-VMSwitchExtension -VMSwitchName internalswitch | where { $_.Vendor -match 'badflyer' } | Enable-VMSwitchExtension
# or
Get-VMSwitchExtension -VMSwitchName internalswitch | where { $_.Vendor -match 'badflyer' } | Disable-VMSwitchExtension
```

That’s all there is to it. After that, your NDIS filter driver will begin to receive traffic from the virtual switch, and will be part of the virtual switch’s driver stack.

```powershell
# To uninstall the driver, simply use netcfg#
#
# netcfg /u <driver installation name from inf>
#
netcfg /u BADFLYER_basicndis
```

To start and stop the driver server, you can use:

```powershell
# net start <name of service>
# net stop <name of service>
# Stop-Service <name of service>
# Start-Service <name of service>

# EX: (Note, in this example this is not the same as the name given to netcfg)
#    You can make them the same if you configure your inf that way, but the service
#    name is not necessarily the same as the name of the section used for installation.
net start basicndis
```