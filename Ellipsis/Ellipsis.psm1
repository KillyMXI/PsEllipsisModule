
$Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue
$Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue 

Foreach( $import in (@() + $Public + $Private) )
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error "Failed to import '$($import.FullName)'"
    }
}
