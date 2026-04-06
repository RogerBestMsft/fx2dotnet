Set-StrictMode -Version Latest

function Unquote-YamlValue {
    param([AllowNull()] [string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $trimmed = $Value.Trim()
    if ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }

    return $trimmed
}

function Read-ExtensionManifest {
    param([Parameter(Mandatory)] [string]$Path)

    $lines = Get-Content -Path $Path
    $manifest = [ordered]@{
        schema_version = ""
        extension      = [ordered]@{}
        requires       = [ordered]@{
            speckit_version = ""
            tools           = @()
            commands        = @()
        }
        provides       = [ordered]@{
            commands = @()
            config   = @()
        }
        hooks          = [ordered]@{}
        tags           = @()
    }

    $section = ""
    $subsection = ""
    $currentTool = $null
    $currentCommand = $null
    $currentConfig = $null
    $currentHookName = ""

    foreach ($line in $lines) {
        if ($line -match '^schema_version:\s*(.+)$') {
            $manifest.schema_version = Unquote-YamlValue $Matches[1]
            continue
        }

        if ($line -match '^extension:$') { $section = 'extension'; $subsection = ''; continue }
        if ($line -match '^requires:$') { $section = 'requires'; $subsection = ''; continue }
        if ($line -match '^provides:$') { $section = 'provides'; $subsection = ''; continue }
        if ($line -match '^hooks:$') { $section = 'hooks'; $subsection = ''; continue }
        if ($line -match '^tags:$') { $section = 'tags'; $subsection = ''; continue }

        switch ($section) {
            'extension' {
                if ($line -match '^\s{2}([a-z_]+):\s*(.+)$') {
                    $manifest.extension[$Matches[1]] = Unquote-YamlValue $Matches[2]
                }
            }
            'requires' {
                if ($line -match '^\s{2}speckit_version:\s*(.+)$') {
                    $manifest.requires.speckit_version = Unquote-YamlValue $Matches[1]
                    continue
                }

                if ($line -match '^\s{2}tools:$') { $subsection = 'tools'; continue }
                if ($line -match '^\s{2}commands:$') { $subsection = 'commands'; continue }

                if ($subsection -eq 'tools') {
                    if ($line -match '^\s{4}- name:\s*(.+)$') {
                        $currentTool = [pscustomobject]@{ name = Unquote-YamlValue $Matches[1] }
                        $manifest.requires.tools += $currentTool
                        continue
                    }

                    if ($null -ne $currentTool -and $line -match '^\s{6}([a-z_]+):\s*(.+)$') {
                        $key = $Matches[1]
                        $value = Unquote-YamlValue $Matches[2]
                        if ($key -eq 'required') {
                            $value = [bool]::Parse($value.ToLowerInvariant())
                        }
                        $currentTool | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
                    }
                }

                if ($subsection -eq 'commands' -and $line -match '^\s{4}-\s*(.+)$') {
                    $manifest.requires.commands += Unquote-YamlValue $Matches[1]
                }
            }
            'provides' {
                if ($line -match '^\s{2}commands:$') { $subsection = 'commands'; continue }
                if ($line -match '^\s{2}config:$') { $subsection = 'config'; continue }

                if ($subsection -eq 'commands') {
                    if ($line -match '^\s{4}- name:\s*(.+)$') {
                        $currentCommand = [pscustomobject]@{ name = Unquote-YamlValue $Matches[1] }
                        $manifest.provides.commands += $currentCommand
                        continue
                    }

                    if ($null -ne $currentCommand -and $line -match '^\s{6}([a-z_]+):\s*(.+)$') {
                        $key = $Matches[1]
                        $value = Unquote-YamlValue $Matches[2]
                        if ($key -eq 'aliases') {
                            $value = @($value.Trim('[', ']') -split ',' | ForEach-Object { Unquote-YamlValue $_ } | Where-Object { $_ })
                        }
                        $currentCommand | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
                    }
                }

                if ($subsection -eq 'config') {
                    if ($line -match '^\s{4}- name:\s*(.+)$') {
                        $currentConfig = [pscustomobject]@{ name = Unquote-YamlValue $Matches[1] }
                        $manifest.provides.config += $currentConfig
                        continue
                    }

                    if ($null -ne $currentConfig -and $line -match '^\s{6}([a-z_]+):\s*(.+)$') {
                        $key = $Matches[1]
                        $value = Unquote-YamlValue $Matches[2]
                        if ($key -eq 'required') {
                            $value = [bool]::Parse($value.ToLowerInvariant())
                        }
                        $currentConfig | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
                    }
                }
            }
            'hooks' {
                if ($line -match '^\s{2}([a-z_]+):$') {
                    $currentHookName = $Matches[1]
                    $manifest.hooks[$currentHookName] = [ordered]@{}
                    continue
                }

                if ($currentHookName -and $line -match '^\s{4}([a-z_]+):\s*(.+)$') {
                    $key = $Matches[1]
                    $value = Unquote-YamlValue $Matches[2]
                    if ($key -eq 'optional') {
                        $value = [bool]::Parse($value.ToLowerInvariant())
                    }
                    $manifest.hooks[$currentHookName][$key] = $value
                }
            }
            'tags' {
                if ($line -match '^\s{2}-\s*(.+)$') {
                    $manifest.tags += Unquote-YamlValue $Matches[1]
                }
            }
        }
    }

    return [pscustomobject]$manifest
}
