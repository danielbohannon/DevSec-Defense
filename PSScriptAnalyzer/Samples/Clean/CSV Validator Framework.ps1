# --- begin test-csv.ps1 ---
param(
    [string]$Path = $(throw "require CSV path!"),
    [string]$RulesetPath = $(throw "require Ruleset path!")
)

$csvFiles = Resolve-Path -Path $Path

# load rules
if ((Test-Path (Resolve-Path $RulesetPath))) {
    
    # ruleset is found, execute and assign result to variable (should be hashtable)
    $ruleset = (& $RulesetPath)
    
    write-host "Ruleset has $($ruleset.firstrow.keys.count) first row rule(s)"
    write-host "Ruleset has $($ruleset.allrows.keys.count) all rows rule(s)"

    if (-not ($ruleset.firstrow)) {
        write-warning "ruleset $rulesetpath has no rules for first row (list/table validation)"
    }
    
    if (-not ($ruleset.allrows)) {
        throw "ruleset $rulesetpath has no rules for allrows (row validation)"
    }
    
} else {
    throw "Could not find ruleset $rulesetpath"
}

write-verbose "Found $($csvfiles.length) file(s)"

$csvFiles | where-object {
        
    # only pass on CSV files
    [io.path]::GetExtension( $_.providerpath ) -eq ".csv"
    
    } | foreach-object { 
    
        write-host "processing CSV $_"
        # import csv files        
        
        $firstRow = $true
        $rowcount = 0
        
        import-csv $_.path <#| select -first 20#> | foreach-object {
            
            write-host "row $rowcount"
            $currentRow = $_
            
            # process "first row only" rules, only on first row            
            if ($firstRow) {
                
                $ruleset.FirstRow.Keys | % {
                    write-host -nonewline "Processing rule $_ ... "
                    
                    # execute the scriptblock with the current row as an argument
                    # the scriptblock is the value of the imported hashtable
                    if ((& $ruleset.firstrow[$_] $currentRow)) {
                    
                        write-host -fore green "passed"
                    
                    } else {
                        # displays green in ISE (lol)
                        write-host -fore red "failed"
                    
                    }
                }
                
                $firstRow = $false
            }
            
            # process "all rows" rules                
            $ruleset.AllRows.Keys | % {
                write-host -nonewline "Processing rule $_ ... "

                # execute the scriptblock with the current row as an argument
                # the scriptblock is the value of the imported hashtable                                
                if ((& $ruleset.AllRows[$_] $currentRow)) {
                
                    write-host -fore green "passed"
                
                } else {
                    # displays green in ISE (lol)
                    write-host -fore red "failed"                
                }
            }
            
            $rowcount++
        }
    }
# --- end test-csv.ps1 ---

# --- begin ruleset-sample.ps1 ---
@{
    FirstRow = @{
            ruleVerifyColumns = {
                param($row)
                
                $columns = @("u_logon_name",
                  "u_user_security_password",
                  "g_user_id_changed_by",
                  "i_account_status",
                  "d_date_registered",
                  "d_date_last_changed",
                  "d_date_created")
                
                $count = 0
                
                $columns | ForEach-Object <# alias = % #> {
                    if ($row.psobject.members.Match($_)) { $count++ }
                }            
            
            $count -eq $columns.length
        };
    };
    
    AllRows = @{
        ruleLogonNameLengthGreaterThan8 = {
            param($row)        
            $row.u_logon_name -gt 8
        };
        
        ruleChangedByIsValidGuid = {
            param($row)

            try {
                # try cast to guid and swallow result if successful
               [guid]$row.g_user_id_changed_by > $null
               
                $true
            
            } catch { $false }
        };
   }
}

# --- end ruleset-sample.ps1 ---

