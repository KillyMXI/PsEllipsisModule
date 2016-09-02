
function CountMetric([string[]]$Array)
{
    return $Array.Count;
}

function SummaryLengthMetric([string[]]$Array, [int]$Correction=0)
{
    return ($Array | %{ ([string]$_).Length + $Correction } | Measure-Object -Sum).Sum;
}
