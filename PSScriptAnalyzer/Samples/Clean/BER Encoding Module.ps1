<#
.SYNOPSIS
    BER encoding library

.DESCRIPTION
    Takes ASN types integer, octet (string), octet (byte array), and OID
    (string) values and encodes into byte array using Basic Encoding Rules (BER)
    BER encoding is used for SNMP, X.509 certificates, etc.

    There will be a companion BER decoding library posted soon. There will also
    be a SNMP library that makes use of BER encoding and decoding libraries

.NOTES
    Author: Parul Jain, paruljain@hotmail.com
    Version: 0.1, April 21, 2012
    Requires: PowerShell v2 or better

.EXAMPLE
    # The following constructs a GetRequest SNMP message based on
    # http://www.rane.com/note161.html
    $varbindList = encOID '1.3.6.1.4.1.2680.1.2.7.3.2.0' | encNull | encSeq | encSeq
    $pdu = ((encInt 1 | encInt 0 | encInt 0) + $varbindList) | encSeq 0xA0
    $message = ((encInt 0 | encOctet 'private') + $pdu) | encSeq
#>

# We need binary right shift for OID encoding. There is no shift in PS v2
# So we add it via inline C# code. Very cool!
Add-Type @"
public class Shift {
   public static long  Right(long x,  int count) { return x >> count; }
}                    
"@

function byte2hex {
    # Not really a part of this library. Helps debug the code
    # Takes byte array and converts to hex printable string

    [string]$ret = ''
    $input | % { $ret += '{0:X2} ' -f $_ }
    $ret.TrimEnd(' ')
}

function trimLeft([byte[]]$buffer) {
    # Removes leading 0 value bytes from a byte array

    $i = 0
    while ($buffer[$i] -eq 0) { $i++ } 
    $buffer[$i..($buffer.length-1)]
}

function encLength([long]$length) {
    # BER code is TLV - Type Length Value
    # Length itself needs to be encoded if more than 127 bytes
    # This function takes the length (of the Value) and encodes it

    if ($length -lt 128) { return [byte]$length }
    # The length is more than 127 so do the coding
    $buffer = [BitConverter]::GetBytes($length)
    # Reverse to make Big-endian
    [Array]::Reverse($buffer)
    # Eliminate leading zeros
    [byte[]]$buffer = trimLeft $buffer
    # Add length for the length and return
    @(128 + $buffer.length) + $buffer
}

function encInt([int]$value) {
    # Encodes Integer value to BER and adds to input stream
    # BER type for integer is 2

    $b = [BitConverter]::GetBytes($value)
    [Array]::Reverse($b)
    [byte[]]$b = trimLeft $b
    $input + [byte[]](2, $b.length) + $b
}

function encOctet($buffer) {
    # Encodes octet string to BER and adds to input stream
    # The string can be provided as [string] or as [byte[]]
    # BER type for octet string is 4

    if ($buffer -is [string]) { $b = [Text.Encoding]::UTF8.GetBytes($buffer) }
        elseif ($buffer -is [byte[]]) { $b = $buffer }
            else { throw('Must be string or byte[] type') }
    $input + [byte[]](4, (encLength $b.length)) + $b
}

function encOID ([string]$oid) {
    # Encodes OID to BER and adds to input stream
    # BER OID encoding is the most complex of all BER encoding
    # BER type for OID is 6

    # Remove any starting or trailing . from OID string
    $oid = ($oid.TrimStart('.')).TrimEnd('.')
    
    $octets = $oid.split('.')
    if ($octets.count -lt 2) { throw 'Error: Invalid OID; must have at least two octects' }
    if ([int]$octets[0] -gt 2 -or [int]$octets[1] -gt 39) { throw 'Error: Invalid OID' }
    [byte[]]$buffer = @()
    $buffer += 40 * [int]$octets[0] + [int]$octets[1] # First two octets encode special
    # Encode remaining octets normally
    if ($octets.count -gt 2) {
        for($i=2; $i -lt $octets.count; $i++) {
            [byte[]]$buff= @()
            $value = [long]$octets[$i]
            do {
                $b = [System.BitConverter]::GetBytes($value)
                $b[0] = $b[0] -bor 0x80
                $buff += $b[0]
                $value = [shift]::right($value, 7)
            } until ($value -eq 0)
            $buff[0] = $buff[0] -band 0x7F
            [array]::Reverse($buff)
            $buffer += $buff
        }
    }
    $input + [byte[]](6, (encLength $buffer.length)) + $buffer
}

function encNull {
    # Adds BER Null value to input stream
    # BER type for Null is 5

    $input + [byte[]](5, 0)
}

function encSeq([byte]$type=0x30) {
    # Encodes input stream into a BER Sequence
    # For BER Type, 0x30 is used by default but any other Type value can
    # be provided

    $buffer = @($input)
    [byte[]]($type, (encLength $buffer.length)) + $buffer
}
        
