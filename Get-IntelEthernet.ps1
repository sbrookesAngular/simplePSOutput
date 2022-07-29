# <copyright>
# INTEL CONFIDENTIAL
#
# Copyright 2021 Intel Corporation
#
# This software and the related documents are Intel copyrighted materials, and your use of
# them is governed by the express license under which they were provided to you ("License").
# Unless the License provides otherwise, you may not use, modify, copy, publish, distribute,
# disclose or transmit this software or the related documents without Intel's prior written
# permission.
#
# This software and the related documents are provided as is, with no express or implied
# warranties, other than those that are expressly stated in the License.
#
# <copyright>

#.ExternalHelp IntelEthernetCmdlets.dll-Help.xml
function Get-IntelEthernet
{
    [CmdletBinding()]
    Param(
    [parameter(Mandatory = $false)]
    [SupportsWildcards()]
    [ValidateNotNullOrEmpty()]
    [String[]]
    $Name = '',
    [parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [object[]]
    $Adapter = $null
    )
    Begin
    {
        $AdapterName = $Name
        $script:ErrorMessagesGet = @()
        $script:WarningMessagesGet = @()
        $FinalObject = @()
        GetIntelEthernetDevices
        if ($null -ne $script:SupportedAdapters)
        {
            $script:MSNetAdapters = Get-NetAdapter -InterfaceDescription $SupportedAdapters.Name -ErrorAction SilentlyContinue
        }
        GetIntelDriverInfo
        $script:MSNetHwInfo = Get-NetAdapterHardwareInfo -ErrorAction SilentlyContinue
        $script:MSNetAdvProperty = Get-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue
        $AdapterPropertiesNames = @("NetCfgInstanceId", "DriverVersion", "Port")
        $972Key = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" -Name $AdapterPropertiesNames -ErrorAction SilentlyContinue
    }
    Process
    {
        $Adapters = $Adapter
        $PreProcessedAdapterNames = ValidateGetAdapterNameParams $AdapterName $Adapters
        $AdapterNamesArray = @(GetSupportedAdapters $PreProcessedAdapterNames)

        foreach ($a in $AdapterNamesArray)
        {
            $TmpStatusMsg = CheckDeviceError $a
            if (-not [string]::IsNullOrEmpty($TmpStatusMsg))
            {
                $Script:WarningMessagesGet += $TmpStatusMsg
            }

            $SupportedSpeeds = GetAdapterSupportedSpeeds $a
            $AdapterStatuses = GetAdapterStatus $a
            $BusTypes = GetAdapterBusType $a
            $Capabilities = GetAdapterCapabilities $a $SupportedSpeeds
            $ConnectionNames = GetAdapterConnectionName $a
            $DDPPackageNameAndVersions = GetAdapterDDPPackageNameAndVersion $a
            $DDPPackageTrackIds = GetAdapterDDPPackageTrackId $a
            $DeviceStatuses = GetAdapterDeviceStatus $a $SupportedSpeeds
            $DriverVersion = GetDriverVersion $a
            $EEEStatuses = GetAdapterEEEStatus $a
            $ETrackIDs = GetAdapterETrackId $a
            $FullDuplex = GetFullDuplex $a
            $LinkSpeedDuplex = GetLinkSpeedDuplex $a
            $MaxSpeeds = GetAdapterMaxSpeed $a $SupportedSpeeds
            $MediaTypes = GetAdapterMediaType $a
            $MiniPortNames = GetAdapterMiniPortName $a
            $NVMVersions = GetAdapterNVMVersion $a
            $NegotiatedLinkSpeed = GetAdapterNegotiatedLinkSpeed $a
            $NegotiatedLinkWidth = GetAdapterNegotiatedLinkWidth $a
            $NetlistVersions = GetAdapterNetlistVersion $a
            $OemFwVersions = GetOemFwVersion $a
            $OriginalDisplayNames = GetOriginalDisplayName $a
            $PCIDeviceIDs = GetAdapterPCIDeviceID $a
            $PartNumbers = GetAdapterPartNumber $a
            $PciLocations = GetAdapterPCILocation $a
            $RegistryValues = GetAdapterPropertiesFromRegistry $a $972Key
            $SanMacAddresses = GetAdapterSanMacAddress $a

            # Assemble it all together in PSCustomObject
            $FinalObject += [PsCustomObject] @{
                PSTypeName          = 'IntelEthernetAdapter'
                AdapterStatus       = $AdapterStatuses
                BusType             = $BusTypes.BusType
                BusTypeString       = $BusTypes.BusTypeString
                Capabilities        = $Capabilities
                ConnectionName      = $ConnectionNames
                DDPPackageName      = $DDPPackageNameAndVersions.Name
                DDPPackageTrackId   = $DDPPackageTrackIds
                DDPPackageVersion   = $DDPPackageNameAndVersions.Version
                DeviceStatus        = $DeviceStatuses.DeviceStatus
                DeviceStatusString  = $DeviceStatuses.DeviceStatusString
                DriverVersion       = $DriverVersion
                EEE                 = $EEEStatuses.EEEStatus
                EEEString           = $EEEStatuses.EEEStatusString
                ETrackID            = $ETrackIDs
                FWVersion           = $OemFwVersions
                FullDuplex          = $FullDuplex
                Location            = $PciLocations
                MaxSpeed            = $MaxSpeeds
                MediaType           = $MediaTypes.MediaType
                MediaTypeString     = $MediaTypes.MediaTypeString
                MiniPortInstance    = $MiniPortNames.Instance
                MiniPortName        = $MiniPortNames.Name
                NVMVersion          = $NVMVersions
                Name                = $a
                NegotiatedLinkSpeed       = $NegotiatedLinkSpeed.NegotiatedLinkSpeed
                NegotiatedLinkSpeedString = $NegotiatedLinkSpeed.NegotiatedLinkSpeedString
                NegotiatedLinkWidth       = $NegotiatedLinkWidth.NegotiatedLinkWidth
                NegotiatedLinkWidthString = $NegotiatedLinkWidth.NegotiatedLinkWidthString
                NetlistVersion      = $NetlistVersions
                OriginalDisplayName = $OriginalDisplayNames
                PCIDeviceID         = $PCIDeviceIDs
                PartNumber          = $PartNumbers
                PortNumber          = $RegistryValues.Port
                PortNumberString    = $RegistryValues.PortString
                SANMacAddress       = $SanMacAddresses
                Speed               = $LinkSpeedDuplex.Speed
                SpeedString         = $LinkSpeedDuplex.SpeedString
                }
        }
    }
    End
    {
        $FinalObject | Sort-Object -Property Location

        foreach ($WarningMessage in $WarningMessagesGet)
        {
            Write-Warning $WarningMessage
        }

        foreach ($ErrorMessage in $ErrorMessagesGet)
        {
            Write-Error $ErrorMessage
        }
    }
}


function GetAdapterBusType($AdapterName)
{
    $BusType       = 0
    $BusTypeString = $Messages.Unknown

    foreach ($Bus in $script:BusTypesArray)
    {
        if (($null -ne $Bus) -and ($Bus.InstanceName -eq $AdapterName))
        {
            $BusType       = $Bus.BusType
            $BusTypeString = $BusTypeMap[[int]$Bus.BusType]
            break
        }
    }
    return [PsCustomObject] @{
        BusType       = $BusType
        BusTypeString = $BusTypeString }
}

function GetAdapterConnectionName($AdapterName)
{
    return ($MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).InterfaceAlias
}

function GetAdapterDDPPackageNameAndVersion($AdapterName)
{
    $Name    = $Messages.NotSupported
    $Version = $Messages.NotSupported

    foreach ($DDPPkgName in $script:DDPPkgNamesArray)
    {
       if (($null -ne $DDPPkgName) -and ($DDPPkgName.InstanceName -eq $AdapterName))
       {
            $Name    = [System.Text.Encoding]::ASCII.GetString($DDPPkgName.Name)
            $Version = $DDPPkgName.Major.ToString() + "." + $DDPPkgName.Minor.ToString()
            break
       }
    }
    return [PsCustomObject] @{
        Name    = $Name
        Version = $Version }
}


function GetAdapterDDPPackageTrackId($AdapterName)
{
    $TrackId = $Messages.NotSupported
    $Params = @{Version = [uint32]1; Size = [uint32]12; Type = [uint32]1;}
    $Result = InvokeCimMethod "IntlLan_GetTrackId" $AdapterName "WmiGetTrackId" $Params
    if (($null -ne $Result) -and ($Result.ReturnValue -eq $true))
    {
        $TrackId = '0x{0:X}' -f $Result.Track_Id
    }
    return $TrackId
}


function GetAdapterDeviceStatus($AdapterName, $SupportedSpeeds)
{
    $DeviceStatus = 0
    $DeviceStatusString = $Messages.Unknown

    $AdapterNames = $MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}

    foreach($TmpAdapter in $AdapterNames)
    {
        if ("Up" -eq $TmpAdapter.Status)
        {
            $MaxSpeed = GetAdapterMaxSpeed $AdapterName $SupportedSpeeds
            $CurrentSpeed = (GetLinkSpeedDuplex $AdapterName).Speed
            if ($CurrentSpeed -lt $MaxSpeed)
            {
                $DeviceStatus = 4
                $DeviceStatusString = $Messages.LinkUpNotMax
            }
            else
            {
                $DeviceStatus = 1
                $DeviceStatusString = $Messages.LinkUp
            }
        }
        elseif ("Disconnected" -eq $TmpAdapter.Status)
        {
            $DeviceStatus = 2
            $DeviceStatusString = $Messages.LinkDown
        }
        elseif ("Disabled" -eq $TmpAdapter.Status)
        {
            $DeviceStatus = 0
            $DeviceStatusString = $Messages.Disabled
        }
        elseif ($null -eq ($script:PnpDevice | Where-Object {$_.Name -eq $TmpAdapter.InterfaceDescription}).Service)
        {
            $DeviceStatus = 4
            $DeviceStatusString = $Messages.NotPresent
        }
    }

    return [PsCustomObject] @{
        DeviceStatus       = $DeviceStatus
        DeviceStatusString = $DeviceStatusString}

}

function GetAdapterETrackId($AdapterName)
{
    $ETrackId = $Messages.NotSupported
    foreach ($ETrackId in $script:ETrackIdsArray)
    {
       if (($null -ne $ETrackId) -and ($ETrackId.InstanceName -eq $AdapterName))
       {
           $ETrackId = '0x{0:X}' -f $ETrackId.Id
           break
       }
    }
    return $ETrackId
}


function GetAdapterNVMVersion($AdapterName)
{
    $Version = $Messages.NotSupported
    foreach ($NVMVersion in $script:NVMVersionsArray)
    {
       if (($null -ne $NVMVersion) -and ($NVMVersion.InstanceName -eq $AdapterName))
       {
            $Version = (($NVMVersion.Version -band 0xffff) -shr 8).ToString() + "." + (($NVMVersion.Version -band 0xff)).ToString("X2")
            break
       }
    }
    return $Version
}

function GetAdapterNetlistVersion($AdapterName)
{
    $NetlistVersion = $Messages.NotSupported
    $Params = @{Version = [uint32]1; Size = [uint32]12; Type = [uint32]1;}
    $Result = InvokeCimMethod "IntlLan_GetNVMNetlistInfo" $AdapterName "WmiGetNVMNetlistInfo" $params
    if (($null -ne $Result) -and ($Result.ReturnValue -eq $true))
    {
        $NetlistVersion = [System.Text.Encoding]::ASCII.GetString($Result.VersionStr)
    }
    return $NetlistVersion
}

function GetAdapterPartNumber($AdapterName)
{
    $PartNumberString = $Messages.NotSupported
    foreach ($PartNumber in $script:PartNumbersArray)
    {
       if (($null -ne $PartNumber) -and ($PartNumber.InstanceName -eq $AdapterName))
       {
            $PartNumberString = [System.Text.Encoding]::ASCII.GetString($PartNumber.PartNumberString)
            break
       }
    }
    return $PartNumberString
}

function GetAdapterSanMacAddress($AdapterName)
{
    $MacAddress = $Messages.NotSupported

    foreach ($SanMacAddress in $script:SanMacAddressesArray)
    {
        if (($null -ne $SanMacAddress) -and ($SanMacAddress.InstanceName -eq $AdapterName))
        {
            $MacAddress = ""
            for ($i = 0; $i -lt 6; $i++)
            {
                # convert to string hex representation; X - hex, 2 - add leading zeroes if needed
                $MacAddress += $SanMacAddress.SanMacAddr[$i].ToString("X2")
            }
            break
        }
    }
    return $MacAddress
}

function GetAdapterMediaType($AdapterName)
{
    $MediaType = [PsCustomObject] @{
        MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_UNKNOWN
        MediaTypeString = $Messages.Unknown }

    $ServiceName = ($script:SupportedAdapters | Where-Object {$_.Name -eq $AdapterName}).ServiceName

    switch ($ServiceName)
    {
        icea  { $MediaType = GetAdapterMediaTypeIce $AdapterName; break }
        scea  { $MediaType = GetAdapterMediaTypeIce $AdapterName; break }
        i40ea { $MediaType = GetAdapterMediaTypeI40e $AdapterName; break }
        i40eb { $MediaType = GetAdapterMediaTypeI40e $AdapterName; break }
    }
    return $MediaType
}

function GetAdapterMediaTypeIce($AdapterName)
{
    foreach ($PhyInfo in $script:PhyInfoArray)
    {
        if (($null -ne $PhyInfo) -and ($PhyInfo.InstanceName -eq $AdapterName) -and ($PhyInfo.PhyInfo.Length -ge 8))
        {
            # Interpreting PhyInfo array values:
            # 0 == PHY type
            # 1 == link info <-- Bit 0 (value of 1 means has link)
            # 2 == an_info
            # 3 == ext_info
            # 4 == module type [0]
            # 5 == module type [1]
            # 6 == module type [2]
            # 7 == media interface  <-- 1=Backplane, 2=QSFP, 3=SFP
            $PhyType = $PhyInfo.PhyInfo[0];
            $LinkInfo = $PhyInfo.PhyInfo[1];
            $MediaInterface = $PhyInfo.PhyInfo[7];

            $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Unknown
            $MediaTypeString = $Messages.Unknown

            if ($LinkInfo -band 0x01)
            {
                switch ($PhyType)
                {
                    {$_ -in [int][CVL_PHY_TYPE]::CVL10GSFIAOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL25GAUIAOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL40GXLAUIAOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL50GLAUI2AOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL50GAUI2AOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL50GAUI1AOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL100GCAUI4AOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL100GAUI4AOC_ACC,
                    [int][CVL_PHY_TYPE]::CVL100GAUI2AOC_ACC}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_AOC_ACC
                        $MediaTypeString = $Messages.AOCACC
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL5GBaseKR,
                    [int][CVL_PHY_TYPE]::CVL10GBaseKR,
                    [int][CVL_PHY_TYPE]::CVL25GBaseKR}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR
                        $MediaTypeString = $Messages.BackplaneKR
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL25GBaseKR1)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR1
                        $MediaTypeString = $Messages.BackplaneKR1
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL50GBaseKR2)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR2
                        $MediaTypeString = $Messages.BackplaneKR2
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100GBaseKR2PAM4)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR2_PAM4
                        $MediaTypeString = $Messages.BackplaneKR2PAM4
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL40GBaseKR4,
                    [int][CVL_PHY_TYPE]::CVL100GBaseKR4}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR4
                        $MediaTypeString = $Messages.BackplaneKR4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100GBaseKR4PAM4)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR4_PAM4
                        $MediaTypeString = $Messages.BackplaneKR4PAM4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL50GBaseKRPAM4)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR_PAM4
                        $MediaTypeString = $Messages.BackplaneKRPAM4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL25GBaseKRS)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KR_S
                        $MediaTypeString = $Messages.BackplaneKRS
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL1000BaseKX,
                    [int][CVL_PHY_TYPE]::CVL2Point5GBaseKX}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Backplane_KX
                        $MediaTypeString = $Messages.BackplaneKX
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL10GSFIC2C,
                    [int][CVL_PHY_TYPE]::CVL25GAUIC2C,
                    [int][CVL_PHY_TYPE]::CVL40GXLAUI,
                    [int][CVL_PHY_TYPE]::CVL50GLAUI2,
                    [int][CVL_PHY_TYPE]::CVL50GAUI2,
                    [int][CVL_PHY_TYPE]::CVL50GAUI1,
                    [int][CVL_PHY_TYPE]::CVL100GCAUI4,
                    [int][CVL_PHY_TYPE]::CVL100GAUI4,
                    [int][CVL_PHY_TYPE]::CVL100GAUI2}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Chip_to_Chip
                        $MediaTypeString = $Messages.ChiptoChip
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL1000BaseT,
                    [int][CVL_PHY_TYPE]::CVL2Point5GBaseT,
                    [int][CVL_PHY_TYPE]::CVL5GBaseT,
                    [int][CVL_PHY_TYPE]::CVL10GBaseT,
                    [int][CVL_PHY_TYPE]::CVL25GBaseT}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Copper_T
                        $MediaTypeString = $Messages.CopperT
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100BaseTX)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Copper_TX
                        $MediaTypeString = $Messages.CopperTX
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL10GSFIDA)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach
                        $MediaTypeString = $Messages.DirectAttach
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100GBaseCP2)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CP2
                        $MediaTypeString = $Messages.DirectAttachCP2
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL25GBaseCR)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR
                        $MediaTypeString = $Messages.DirectAttachCR
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL25GBaseCR1)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR1
                        $MediaTypeString = $Messages.DirectAttachCR1
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL50GBaseCR2)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR2
                        $MediaTypeString = $Messages.DirectAttachCR2
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL40GBaseCR4,
                    [int][CVL_PHY_TYPE]::CVL100GBaseCR4}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR4
                        $MediaTypeString = $Messages.DirectAttachCR4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL50GBaseCRPAM4)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR_PAM4
                        $MediaTypeString = $Messages.DirectAttachCRPAM4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL25GBaseCRS)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Direct_Attach_CR_S
                        $MediaTypeString = $Messages.DirectAttachCRS
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100GBaseDR)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_DR
                        $MediaTypeString = $Messages.FiberDR
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL50GBaseFR)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_FR
                        $MediaTypeString = $Messages.FiberFR
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL10GBaseLR,
                    [int][CVL_PHY_TYPE]::CVL25GBaseLR,
                    [int][CVL_PHY_TYPE]::CVL50GBaseLR}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_LR
                        $MediaTypeString = $Messages.FiberLR
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL40GBaseLR4,
                    [int][CVL_PHY_TYPE]::CVL100GBaseLR4}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_LR4
                        $MediaTypeString = $Messages.FiberLR4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL1000BaseLX)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_LX
                        $MediaTypeString = $Messages.FiberLX
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL10GBaseSR,
                    [int][CVL_PHY_TYPE]::CVL25GBaseSR,
                    [int][CVL_PHY_TYPE]::CVL50GBaseSR}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_SR
                        $MediaTypeString = $Messages.FiberSR
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL100GBaseSR2)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_SR2
                        $MediaTypeString = $Messages.FiberSR2
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL40GBaseSR4,
                    [int][CVL_PHY_TYPE]::CVL100GBaseSR4}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_SR4
                        $MediaTypeString = $Messages.FiberSR4
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL1000BaseSX)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_SX
                        $MediaTypeString = $Messages.FiberSX
                        break
                    }
                    ([int][CVL_PHY_TYPE]::CVL2Point5gBaseX)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Fiber_X
                        $MediaTypeString = $Messages.FiberX
                        break
                    }
                    {$_ -in [int][CVL_PHY_TYPE]::CVL100MSGMII,
                    [int][CVL_PHY_TYPE]::CVL1GSGMII}
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_SGMII
                        $MediaTypeString = $Messages.SGMII
                        break
                    }
                    default
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Unknown
                        $MediaTypeString = $Messages.Unknown
                        break
                    }
                }
            }
            else
            {
                switch ($MediaInterface)
                {
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_BACKPLANE)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_BACKPLANE
                        $MediaTypeString = $Messages.Backplane
                        break
                    }
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_QSFP)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_QSFP
                        $MediaTypeString = $Messages.QSFP
                        break
                    }
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_SFP)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_SFP
                        $MediaTypeString = $Messages.SFP
                        break
                    }
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_BASE_T)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_BASE_T
                        $MediaTypeString = $Messages.CopperT
                        break
                    }
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_SGMII)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_SGMII
                        $MediaTypeString = $Messages.SGMII
                        break
                    }
                    ([int][CPK_PHY_INFO]::CPK_PHYINFO_MEDIA_FIBER)
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_INTERFACE_CVL_FIBER
                        $MediaTypeString = $Messages.Fiber
                        break
                    }
                    default
                    {
                        $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_CVL_Unknown
                        $MediaTypeString = $Messages.Unknown
                        break
                    }
                }
            }
       }
    }

    return [PsCustomObject] @{
        MediaType = $MediaType
        MediaTypeString = $MediaTypeString }
}

function GetAdapterMediaTypeI40e($AdapterName)
{
    foreach ($PhyInfo in $script:PhyInfoArray)
    {
        if (($null -ne $PhyInfo) -and ($PhyInfo.InstanceName -eq $AdapterName) -and ($PhyInfo.PhyInfo.Length -ge 13))
        {
            $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_UNKNOWN
            $MediaTypeString = $Messages.Unknown

            $PhyType = $PhyInfo.PhyInfo[0];
            $LinkType = ([uint32]$PhyInfo.PhyInfo[11] -shl 24) + ([uint32]$PhyInfo.PhyInfo[10] -shl 16) + ([uint32]$PhyInfo.PhyInfo[9] -shl 8) + [uint32]$PhyInfo.PhyInfo[8];
            $LinkTypeExt = $PhyInfo.PhyInfo[12];

            if ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_EMPTY)
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_UNKNOWN
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_40GBASE_KR4) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_KR) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25GBase_KR))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_BACKPLANE
                $MediaTypeString = $Messages.Backplane
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_SFP_Cu) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_CR1))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SFPDIRECTATTACH
                $MediaTypeString = $Messages.SFPDirectAttach
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_40GBASE_LR4) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_LR) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25GBase_LR))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_LR_FIBER
                $MediaTypeString = $Messages.LRFiber
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_SR) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_40GBASE_SR4) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25GBase_SR))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SR_FIBER
                $MediaTypeString = $Messages.SRFiber
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_T) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_1000BASE_T) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_100BASE_TX) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_2_5GBASE_T) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_5GBASE_T))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_COPPER
                $MediaTypeString = $Messages.Copper
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_CR1_CU) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_40GBASE_CR4_CU) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_40GBASE_CR4))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_QSFPDIRECTATTACH
                $MediaTypeString = $Messages.QSFPDirectAttach
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_10GBASE_KX4) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_1000BASE_KX))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_KX4BACKPLANE
                $MediaTypeString = $Messages.KXBackplane
            }
            elseif (($LinkType -band [int][LinkType]::LINK_TYPE_XAUI) -or
                    ($LinkType -band [int][LinkType]::LINK_TYPE_XLAUI))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_XAUI
                $MediaTypeString = $Messages.XAUI
            }
            elseif (($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25G_AOC) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25G_ACC) -or
                    ($LinkTypeExt -band [int][LinkTypeExt]::LINK_TYPE_25GBase_CR))
            {
                $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SFP28DIRECTATTACH
                $MediaTypeString = $Messages.SFP28DirectAttach
            }
            # old FW or HW different than XL710
            elseif ($LinkTypeExt -eq 0 -and $LinkType -eq 0)
            {
                if (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_40GBASE_KR4) -or
                    ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_KR) -or
                    ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_KR))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_BACKPLANE
                    $MediaTypeString = $Messages.Backplane
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_SFPP_CU) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_CR1))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SFPDIRECTATTACH
                    $MediaTypeString = $Messages.SFPDirectAttach
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_40GBASE_LR4) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_LR) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_LR))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_LR_FIBER
                    $MediaTypeString = $Messages.LRFiber
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_SR) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_40GBASE_SR4) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_SR))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SR_FIBER
                    $MediaTypeString = $Messages.SRFiber
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_T) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_1000BASE_T) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_100BASE_TX))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_COPPER
                    $MediaTypeString = $Messages.Copper
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_CR1_CU) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_40GBASE_CR4_CU) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_40GBASE_CR4))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_QSFPDIRECTATTACH
                    $MediaTypeString = $Messages.QSFPDirectAttach
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_10GBASE_KX4) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_1000BASE_KX))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_KX4BACKPLANE
                    $MediaTypeString = $Messages.KXBackplane
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_XAUI) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_XLAUI))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_XAUI
                    $MediaTypeString = $Messages.XAUI
                }
                elseif (($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_AOC) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_ACC) -or
                        ($PhyType -eq [int][I40E_PHY_TYPE]::I40E_PHY_TYPE_25GBASE_CR))
                {
                    $MediaType = [int][NCS_ADAPTER_MEDIA_TYPE]::NCS_MEDIA_SFP28DIRECTATTACH
                    $MediaTypeString = $Messages.SFP28DirectAttach
                }
            }
        }
    }

    return [PsCustomObject] @{
        MediaType = $MediaType
        MediaTypeString = $MediaTypeString }
}

function GetAdapterPCILocation($AdapterName)
{
    $PCILocation = $Messages.NotSupported
    foreach ($HwInfo in $MSNetHwInfo)
    {
        if ($AdapterName -eq $HwInfo.ifDesc)
        {
            $PCILocation = $HwInfo.Bus.ToString() + ":" + $HwInfo.Device.ToString()  + ":" + $HwInfo.Function.ToString() + ":" + $HwInfo.Segment.ToString()
            break
        }
    }
    return $PCILocation
}

function GetOriginalDisplayName($AdapterName)
{
    return ($MSNetHwInfo | Where-Object {$_.ifDesc -eq $AdapterName}).ifDesc
}

function GetOemFwVersion($AdapterName)
{
    $Version = $Messages.NotSupported
    foreach ($FwVersion in $script:FwVersionsArray)
    {
       if ($FwVersion.InstanceName -eq $AdapterName)
       {
            # driver can return and array of zeroes - don't attempt to construct a string using it
            if ($FwVersion.SingleNvmVersion[0] -ne 0)
            {
                $Version = [System.Text.Encoding]::ASCII.GetString($FwVersion.SingleNvmVersion)
            }
            break
       }
    }
    return $Version
}

function GetAdapterPCIDeviceID($AdapterName)
{
    return ($MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).PnPDeviceID
}


function GetAdapterNegotiatedLinkWidth($AdapterName)
{
    $NegotiatedLinkWidth = ($MSNetHwInfo | Where-Object {$_.ifDesc -eq $AdapterName}).PciExpressCurrentLinkWidth
    $NegotiatedLinkWidthString = "x" + ($MSNetHwInfo | Where-Object {$_.ifDesc -eq $AdapterName}).PciExpressCurrentLinkWidth.ToString()
    return [PsCustomObject] @{
        NegotiatedLinkWidth = $NegotiatedLinkWidth
        NegotiatedLinkWidthString = $NegotiatedLinkWidthString }
}


function GetAdapterNegotiatedLinkSpeed($AdapterName)
{
    $NegotiatedLinkSpeed = ($MSNetHwInfo | Where-Object {$_.ifDesc -eq $AdapterName}).PciExpressCurrentLinkSpeedEncoded
    switch ($NegotiatedLinkSpeed)
    {
        0 {$NegotiatedLinkSpeedString = $Messages.Unknown; break}
        1 {$NegotiatedLinkSpeedString = $Messages.NegLaneSpeed25; break}
        2 {$NegotiatedLinkSpeedString = $Messages.NegLaneSpeed50; break}
        3 {$NegotiatedLinkSpeedString = $Messages.NegLaneSpeed80; break}
        default {$NegotiatedLinkSpeedString = $Messages.Unknown; break}
    }
    return [PsCustomObject] @{
        NegotiatedLinkSpeed = $NegotiatedLinkSpeed
        NegotiatedLinkSpeedString = $NegotiatedLinkSpeedString }
}

function GetLinkSpeedDuplex($AdapterName)
{
    $AdapterObj = $MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}
    $Speed = $AdapterObj.Speed
    $SpeedString = $AdapterObj.LinkSpeed
    $FullDuplex = $AdapterObj.FullDuplex

    if ("Up" -ne $AdapterObj.Status)
    {
        $Speed = 0
        $SpeedString = $Messages.NotAvailable
    }
    elseif ($true -eq $FullDuplex)
    {
        $SpeedString += " " + $Messages.FullDuplex
    }

    return [PsCustomObject] @{
        Speed = $Speed
        SpeedString = $SpeedString }
}

function GetFullDuplex($AdapterName)
{
    $FullDuplex = ($MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).FullDuplex
    if ($null -eq $FullDuplex)
    {
        $FullDuplex = ""
    }
    return $FullDuplex
}

function GetAdapterPropertiesFromRegistry($AdapterName, $972Key)
{
    # Individual Adapter GUID
    $AdapterInstanceID = ($script:MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).InterfaceGuid

    $AdapterRegKey = $972Key | Where-Object {$_.NetCfgInstanceId -Like ($AdapterInstanceID)}

    switch ($AdapterRegKey.Port)
    {
        0 {$PortNumberString = $Messages.PortA; break}
        1 {$PortNumberString = $Messages.PortB; break}
        2 {$PortNumberString = $Messages.PortC; break}
        3 {$PortNumberString = $Messages.PortD; break}
        default {$PortNumberString = $Messages.NotSupported; break}
    }

    return [PsCustomObject] @{
        Port       = $AdapterRegKey.Port
        PortString = $PortNumberString }
}

function GetDriverVersion($AdapterName)
{
    $DriverVersion = ($MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).DriverVersion
    return $DriverVersion
}

function GetAdapterMiniPortName($AdapterName)
{
    $Name = ($script:PnpDevice | Where-Object {$_.Name -eq $AdapterName}).Service
    $Instance = ($script:MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).InterfaceGuid
    return [PsCustomObject] @{
        Name     = $Name
        Instance = $Instance }
}

function GetAdapterMaxSpeed($AdapterName, $SupportedSpeeds)
{
    if ($SupportedSpeeds.Length -gt 0)
    {
        # array is sorted, so we just return the last element
        return $SupportedSpeeds[-1]
    }
    return 0
}

function GetAdapterSupportedSpeeds($AdapterName)
{
    $SpeedDuplex = $MSNetAdvProperty | Where-Object {$_.InterfaceDescription -eq $AdapterName -and $_.RegistryKeyword -eq "*SpeedDuplex"}
    if ($null -ne $SpeedDuplex)
    {
        $RegistryValues = ($SpeedDuplex).ValidRegistryValues
    }

    $SupportedSpeeds = @()

    foreach ($i in $RegistryValues)
    {
        $SupportedSpeeds += $SupportedSpeedsMap[$i]
    }

    return $SupportedSpeeds | Sort-Object
}


function GetAdapterEEEStatus($AdapterName)
{
    $EEELinkAdvertisement = $MSNetAdvProperty | Where-Object {$_.InterfaceDescription -eq $AdapterName -and $_.RegistryKeyword -eq "EEELinkAdvertisement"}

    $EEEStatus = 0
    $EEEStatusString = $Messages.NotSupported

    foreach ($EEE in $script:EEELinkStatusArray)
    {
        if (($null -ne $EEE) -and ($EEE.InstanceName -eq $AdapterName))
        {
            if ($EEE.EEELinkStatus -eq $false)
            {
                if ($EEELinkAdvertisement -gt 0)
                {
                    $EEEStatus = 3 #Not Negotiated
                    $EEEStatusString = $Messages.NotNegotiated
                }
                else
                {
                    $EEEStatus = 1 #Disabled
                    $EEEStatusString = $Messages.Disabled
                }
            }
            else
            {
                $EEEStatus = 2 #Active
                $EEEStatusString = $Messages.Active
            }
       }
    }
    return [PsCustomObject] @{
        EEEStatus       = $EEEStatus
        EEEStatusString = $EEEStatusString }
}

function GetAdapterStatus($AdapterName)
{
    $AdapterStatus = [ADAPTER_STATUS]::Installed -bor [ADAPTER_STATUS]::DriverLoaded -bor [ADAPTER_STATUS]::HasDiag

    $LinkStatus = ($MSNetAdapters | Where-Object {$_.InterfaceDescription -eq $AdapterName}).Status
    if ($LinkStatus -eq 'Up')
    {
        $AdapterStatus = $AdapterStatus -bor [ADAPTER_STATUS]::HasLink
    }
    return $AdapterStatus
}

function GetAdapterCapabilities($AdapterName, $SupportedSpeeds)
{
    $Capabilities = @([int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_VENDOR_INTEL)

    foreach ($SupportedSpeed in $SupportedSpeeds)
    {
        switch ($SupportedSpeed)
        {
            10000000     {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_10_MBPS; break}
            100000000    {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_100_MBPS; break}
            1000000000   {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_1000_MBPS; break}
            2500000000   {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_2500_MBPS; break}
            5000000000   {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_5000_MBPS; break}
            10000000000  {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_10000_MBPS; break}
            40000000000  {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_40000_MBPS; break}
            25000000000  {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_25000_MBPS; break}
            50000000000  {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_50000_MBPS; break}
            100000000000 {$Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_SPEED_100000_MBPS; break}
        }
    }
    # These are always set for CVL
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_PERFORMANCE_PROFILE
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_DIAGNOSTIC_SUPPORT
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_FLASH_SUPPORT
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_CYPRESS
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_IDENTIFY_ADAPTER_SUPPORT
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_NDIS_IOAT
    $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_EXTENDED_DMIX_SUPPORT

    $MSDCB = $MSNetAdvProperty | Where-Object {$_.InterfaceDescription -eq $AdapterName -and $_.RegistryKeyword -eq "*QOS"}
    if ($null -ne $MSDCB)
    {
        $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_DCB
    }

    $JumboFrames = $MSNetAdvProperty | Where-Object {$_.InterfaceDescription -eq $AdapterName -and $_.RegistryKeyword -eq "*JumboPacket"}
    if ($null -ne $JumboFrames)
    {
        $Capabilities += [int][ADAPTER_CAPABILITY]::NCS_ADAPTER_CAP_JUMBO_FRAMES
    }

    return , ($Capabilities | Sort-Object)
}

function GetIntelDriverInfo()
{
    $script:BusTypesArray        = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_BusType -Property BusType -ErrorAction SilentlyContinue
    $script:DDPPkgNamesArray     = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_GetPackageInfo -Property Name, Major, Minor -ErrorAction SilentlyContinue
    $script:ETrackIdsArray       = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_EetrackId -Property Id -ErrorAction SilentlyContinue
    $script:NVMVersionsArray     = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_EepromVersion -Property Version -ErrorAction SilentlyContinue
    $script:SanMacAddressesArray = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_GetSanMacAddress -Property SanMacAddr -ErrorAction SilentlyContinue
    $script:PartNumbersArray     = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_PartNumberString -Property PartNumberString -ErrorAction SilentlyContinue
    $script:PhyInfoArray         = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_GetPhyInfo -Property PhyInfo -ErrorAction SilentlyContinue
    $script:FwVersionsArray      = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_GetOemProductVer -Property SingleNvmVersion -ErrorAction SilentlyContinue
    $script:EEELinkStatusArray   = Get-CimInstance -Namespace "root\wmi" -ClassName IntlLan_EEELinkStatus -Property EEELinkStatus -ErrorAction SilentlyContinue
}
