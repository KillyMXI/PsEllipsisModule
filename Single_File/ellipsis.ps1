
# Ellipsis implementation by KillyMXI
# https://github.com/KillyMXI/PsEllipsisModule/


function Proportion([double]$Left, [double]$Right)
{
    if(($Left -eq 0) -and ($Right -eq 0))
    {
        return 0.5; # left and right sides are equally empty
    }
    else
    {
        return 1.0 * $Left / ($Left + $Right);
    }
}

function CountMetric([string[]]$Array)
{
    return $Array.Count;
}

function SummaryLengthMetric([string[]]$Array, [int]$Correction=0)
{
    return ($Array | %{ ([string]$_).Length + $Correction } | Measure-Object -Sum).Sum;
}

function Format-Ellipsis
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$InputString,
        [parameter(Mandatory=$true)][ValidateRange(3,[int]::MaxValue)][Alias('w')][int]$Width,
        [ValidateSet('count','length','len',ignorecase=$true)][Alias('by')][string]$Weighting = 'length',
        [ValidateRange(0.0,1.0)][Alias('p')][double]$Proportion = 0.5,
        [ValidateSet('none','auto','left','right',ignorecase=$true)][Alias('cut')][string]$CutSegments = 'left',
        [ValidateLength(1,[int]::MaxValue)][Alias('s')][string]$Separator = [IO.Path]::DirectorySeparatorChar,
        [ValidateLength(1,[int]::MaxValue)][Alias('e')][string]$EllipsisString = '...',
        [switch]$Strict
    )

    if($InputString.Length -le $Width)
    {
        return $InputString;
    }

    if($Strict -and (($CutSegments -eq 'left') -or ($CutSegments -eq 'right')))
    {
        # this options make no sense in combination with strict mode
        $CutSegments = 'auto'
    }

    $segments = $InputString.Split(@($Separator), [StringSplitOptions]::None);

    $leftSegments = @();
    $rightSegments = @();
    $deadEnd = $false;
    $lastSegmentLeft = $false;
    while($true)
    {
        $currStr = ($leftSegments + $EllipsisString + $rightSegments) -join $Separator;
        $currLen = $currStr.Length;

        $insertSpace = $Width - $currLen - $Separator.Length;
        $cutSpace = $Width - $currLen;

        if($deadEnd)
        {
            Write-Debug ("`n" + "-"*$Width);

            if(($CutSegments -eq 'none') -or ($cutSpace -eq 0))
            {
                return $currStr;
            }
            if(($CutSegments -eq 'left') -or (($CutSegments -eq 'auto') -and $lastSegmentLeft))
            {
                $lastSeg = $segments[0];
                $EllipsisString = $lastSeg.Substring(0,$cutSpace) + $EllipsisString;
            }
            else
            {
                $lastSeg = $segments[$segments.Count - 1];
                $skip = $lastSeg.Length - $cutSpace;
                $EllipsisString = $EllipsisString + $lastSeg.Substring($skip, $cutSpace);
            }
            return ($leftSegments + $EllipsisString + $rightSegments) -join $Separator;
        }

        $leftMetric = if($Weighting -eq 'count'){ CountMetric $leftSegments }
                                            else{ SummaryLengthMetric $leftSegments $Separator.Length }
        $rightMetric = if($Weighting -eq 'count'){ CountMetric $rightSegments }
                                             else{ SummaryLengthMetric $rightSegments $Separator.Length }
        $currentProportion = Proportion $leftMetric $rightMetric;

        Write-Debug ("{0,3} | {1,3} | {2,-7:0.#####} | {3,3} | {4,3} | {5}" -f `
                     $leftMetric, $rightMetric, $currentProportion, $insertSpace, $cutSpace, $currStr);

        if(($currentProportion -le $Proportion) -and ($Proportion -gt 0.0)) # right is longer; add to left
        {
            $seg = $segments[0];
            $lastSegmentLeft = $true;
            if($seg.Length -le $insertSpace)
            {
                $segments = $segments[1..($segments.Count-1)];
                $leftSegments += @($seg);
            }
            else # too long; try opposite (in strict mode just call it a day)
            {
                $seg = $segments[-1];
                if(!$Strict -and ($seg.Length -le $insertSpace))
                {
                    $segments = $segments[0..($segments.Count-1-1)];
                    $rightSegments = @($seg) + $rightSegments;
                }
                else # too long again; dead end
                {
                    $deadEnd = $true;
                }
            }
        }
        else # left is longer; add to right
        {
            $seg = $segments[-1];
            $lastSegmentLeft = $false;
            if($seg.Length -le $insertSpace)
            {
                $segments = $segments[0..($segments.Count-1-1)];
                $rightSegments = @($seg) + $rightSegments;
            }
            else # too long; try opposite (in strict mode just call it a day)
            {
                $seg = $segments[0];
                if(!$Strict -and ($seg.Length -le $insertSpace))
                {
                    $segments = $segments[1..($segments.Count-1)];
                    $leftSegments += @($seg);
                }
                else # too long again; dead end
                {
                    $deadEnd = $true;
                }
            }
        }
    }
}
