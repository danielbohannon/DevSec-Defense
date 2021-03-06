# Initialization of helper variables
# BizTalk version numbers
${VeRS`ioNb`T`S2004} = "3.0.4902.0"
${V`erSiONb`Ts200`4S`p1} = "3.0.6070.0"
${v`Ers`I`OnBTs2004SP2} = "3.0.7405.0"
${verSIO`N`BT`s2006} = "3.5.1602.0"
${Ver`s`I`Onbts2006R2} = "3.6.1404.0"
${Ve`R`SiOnBtS2009} = "3.8.368.0"
${veRsIonb`Ts20`10} = "3.9.469.0"

# BizTalk edition values
${br`A`Nch} = "Branch"
${D`EvE`lOpER} = "Developer"
${stA`NDaRD} = "Standard"
${e`NterP`R`ISe} = "Enterprise"

# BizTalk version description
${DESCri`PTio`NbT`S2004} = "BizTalk Server 2004"
${Des`CR`i`pt`ioN`BtS2004SP1} = "BizTalk Server 2004 with service pack 1"
${de`sC`RipTI`on`Bt`s2004sp2} = "BizTalk Server 2004 with service pack 2"
${D`e`s`c`RiPTIonbtS2006} = "BizTalk Server 2006"
${d`escRIptio`NBT`S`2006`R2} = "BizTalk Server 2006 R2"
${DES`cRiPtION`B`TS200`6`R2s`p1} = "BizTalk Server 2006 R2 with service pack 1"
${DeS`c`R`ipTIo`N`BTs`2009} = "BizTalk Server 2009"
${D`EScRI`pT`IonBTS2010} = "BizTalk Server 2010"

# BizTalk edition description
${D`ES`CRipT`IoN`Br`ANcH} = "Branch Edition"
${DESCRI`P`TIond`ev`eL`oPer} = "Developer Edition"
${dEsC`Rip`TioNs`T`ANDArd} = "Standard Edition"
${dESc`Ri`pTioNe`NteRPRi`se} = "Enterprise Edition"

# Registry paths
${bIzta`lkre`g`ISTryPath} = "HKLM:\SOFTWARE\Microsoft\BizTalk Server"
${bIZT`ALk200`6SP`1`UN`iNs`T`A`lLr`EgIs`TrypAth} = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Biztalk Server 2006 R2 Service Pack 1 `[KB 974563`]'

${I`Ns`T`Al`lEDvErSIoN} = ${n`ULL}
${In`stalLedE`D`itioN} = ${n`ull}

# Check if BizTalk is installed:
if ((Test-Path ${biZ`TAlkRegis`TR`ypA`TH}) -eq ${tr`uE})
{

# Set location to BizTalk registry key
Set-Location ${biZt`AlKR`E`giSTRy`path}
${k`EY} = Get-ChildItem

# Get version number
${Prod`uCtvErs`IOn} = ${k`Ey}.GetValue("ProductVersion")

switch (${proDUCt`Ve`RSIon})
{

${v`E`Rs`ioNBT`s2004} { ${iN`ST`ALLedvERs`ION} = ${d`Esc`RiPTIo`Nbt`s2004} }
${v`eRsIONBT`s2004sp1} { ${INstA`lL`edvers`ioN} = ${de`SCrIPTio`NBtS200`4`sp1} }
${V`er`siO`NB`Ts`2004Sp2} { ${Inst`ALLeDV`E`R`sion} = ${DE`Scr`IP`T`ioNbTS200`4sp2} }
${Ve`Rs`I`On`Bts2006} { ${I`NsT`A`LLeDvERSiOn} = ${veRs`I`onBts`2006} }
${V`eRS`IONb`Ts2006`R2}
{
if ((Test-Path ${biz`T`A`LK2006`sP1uNInstA`Ll`R`egiSTr`yP`AtH}) -eq ${fA`l`sE})
{
${InS`TAl`LeDV`e`R`sIoN} = ${deS`cripTio`NB`TS200`6r2}
}
else
{
${i`N`STaLL`E`DVeRsIOn} = ${d`esc`RipTI`o`N`BtS2006r`2SP1}
}
}
${Ve`RS`IoNBtS2009} { ${I`N`STaLl`EDveRSI`ON} = ${dEScRIptioNBT`s2009} }
${Ve`Rsion`Bt`s`2010} { ${Ins`T`AlLED`VErsi`On} = ${D`EsC`Ri`Pti`oNBTS2010} }
}
}

if (${in`S`T`AL`leDVeRsI`On} -eq ${N`uLl})
{
Write-Host "BizTalk Server is not installed on this machine."
Exit
}

# Get product edition
${Pr`o`d`uctEDit`iON}= ${k`Ey}.GetValue("ProductEdition")
switch (${p`RoDUC`T`EDItioN})
{
${bRa`NCH} {${iNStal`Le`dEDIt`i`ON} = ${DEsCRipTI`oN`Bran`cH}}
${De`VELO`pEr} {${I`NStall`eD`edit`iON} = ${DES`CrI`ptIONDEV`Elop`er}}
${S`TaNd`ArD} {${IN`STAl`LeDeD`itiOn} = ${dEsc`RiP`Tio`Ns`TA`NDArD}}
${eNter`Pr`IsE} {${I`NStA`LLE`dEdit`iON} = ${d`ESc`RipTion`Ent`ErPRIsE}}
}


Write-Host "BizTalk Server installation found on this machine."
Write-Host "Product version number: $productVersion"
Write-Host "Installed version: $installedVersion"
Write-Host "Installed edition: $installedEdition"
