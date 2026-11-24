# Fetch the selected entries from the official multi-platform export archive.
# HTTPS authenticates the source; ZIP CRC-32 verifies extracted entry integrity.
function Install-ExportTemplates([string]$Url, [string]$Destination, [string[]]$Names) {
    Add-Type -AssemblyName System.Net.Http
    Add-Type -AssemblyName System.IO.Compression
    if (-not ('CosmosCrc32' -as [type])) {
        Add-Type @'
using System;
using System.IO;
public static class CosmosCrc32 {
    public static uint FileChecksum(string path) {
        uint crc = 0xffffffff;
        uint[] table = new uint[256];
        for (uint n = 0; n < 256; n++) {
            uint c = n;
            for (int k = 0; k < 8; k++) c = (c & 1) != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
            table[n] = c;
        }
        using (var input = File.OpenRead(path)) {
            byte[] buffer = new byte[65536];
            int count;
            while ((count = input.Read(buffer, 0, buffer.Length)) > 0)
                for (int i = 0; i < count; i++) crc = table[(crc ^ buffer[i]) & 255] ^ (crc >> 8);
        }
        return crc ^ 0xffffffff;
    }
}
'@
    }
    $client = [Net.Http.HttpClient]::new()
    $client.Timeout = [TimeSpan]::FromMinutes(15)
    function Read-Range([long]$Start, [long]$Length) {
        $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Get, $Url)
        $request.Headers.Range = [Net.Http.Headers.RangeHeaderValue]::new($Start, $Start + $Length - 1)
        $response = $client.SendAsync($request, [Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
        try {
            if ([int]$response.StatusCode -ne 206 -or $response.Content.Headers.ContentRange.From -ne $Start) {
                throw "Official download server did not honor byte range $Start/$Length. No full archive was downloaded."
            }
            $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
            if ($bytes.LongLength -ne $Length) { throw 'Truncated ZIP byte range.' }
            return ,$bytes
        } finally { $response.Dispose(); $request.Dispose() }
    }
    try {
        $head = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Head, $Url)
        $response = $client.SendAsync($head).GetAwaiter().GetResult()
        try {
            $response.EnsureSuccessStatusCode() | Out-Null
            $size = $response.Content.Headers.ContentLength
            if ($null -eq $size -or $size -lt 65557) { throw 'Invalid official template archive length.' }
        } finally { $response.Dispose(); $head.Dispose() }
        $tail = Read-Range ($size - 65557) 65557
        $end = -1
        for ($i = $tail.Length - 22; $i -ge 0; $i--) {
            if ([BitConverter]::ToUInt32($tail, $i) -eq 0x06054b50 -and $i + 22 + [BitConverter]::ToUInt16($tail, $i + 20) -eq $tail.Length) {
                $end = $i
                break
            }
        }
        if ($end -lt 0) { throw 'ZIP central directory not found.' }
        $directorySize = [BitConverter]::ToUInt32($tail, $end + 12)
        $directoryOffset = [BitConverter]::ToUInt32($tail, $end + 16)
        $directory = Read-Range $directoryOffset $directorySize
        $found = 0
        for ($offset = 0; $offset -lt $directory.Length;) {
            if ([BitConverter]::ToUInt32($directory, $offset) -ne 0x02014b50) { throw 'Invalid ZIP central directory entry.' }
            $nameLength = [BitConverter]::ToUInt16($directory, $offset + 28)
            $extraLength = [BitConverter]::ToUInt16($directory, $offset + 30)
            $commentLength = [BitConverter]::ToUInt16($directory, $offset + 32)
            $name = [Text.Encoding]::UTF8.GetString($directory, $offset + 46, $nameLength)
            if ($name.StartsWith('templates/') -and $name.Substring(10) -in $Names) {
                $found++
                $filename = $name.Substring('templates/'.Length)
                $output = Join-Path $Destination $filename
                $crc = [BitConverter]::ToUInt32($directory, $offset + 16)
                $plainSize = [BitConverter]::ToUInt32($directory, $offset + 24)
                if ((Test-Path -LiteralPath $output) -and (Get-Item -LiteralPath $output).Length -eq $plainSize -and [CosmosCrc32]::FileChecksum($output) -eq $crc) {
                    Write-Host "Verified cached template: $filename"
                } else {
                    if ([BitConverter]::ToUInt16($directory, $offset + 10) -ne 8) { throw 'Unsupported template ZIP compression.' }
                    $compressedSize = [BitConverter]::ToUInt32($directory, $offset + 20)
                    $localOffset = [BitConverter]::ToUInt32($directory, $offset + 42)
                    $local = Read-Range $localOffset 30
                    if ([BitConverter]::ToUInt32($local, 0) -ne 0x04034b50) { throw 'Invalid template local header.' }
                    $dataOffset = $localOffset + 30 + [BitConverter]::ToUInt16($local, 26) + [BitConverter]::ToUInt16($local, 28)
                    Write-Host "Downloading $filename ($([math]::Round($compressedSize / 1MB, 1)) MiB)"
                    $compressed = Read-Range $dataOffset $compressedSize
                    $memory = [IO.MemoryStream]::new($compressed, $false)
                    $deflate = [IO.Compression.DeflateStream]::new($memory, [IO.Compression.CompressionMode]::Decompress)
                    $file = [IO.File]::Create("$output.tmp")
                    try { $deflate.CopyTo($file) } finally { $file.Dispose(); $deflate.Dispose(); $memory.Dispose() }
                    if ((Get-Item -LiteralPath "$output.tmp").Length -ne $plainSize -or [CosmosCrc32]::FileChecksum("$output.tmp") -ne $crc) {
                        throw "Template size/CRC mismatch: $filename"
                    }
                    Move-Item -LiteralPath "$output.tmp" -Destination $output -Force
                    Write-Host "Verified template: $filename"
                }
            }
            $offset += 46 + $nameLength + $extraLength + $commentLength
        }
        if ($found -ne $Names.Count) { throw "Expected $($Names.Count) export templates, found $found." }
    } finally { $client.Dispose() }
}
