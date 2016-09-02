
<# 
 .SYNOPSIS
 
  Ellipsis function to fit your paths or any other strings into screen.


 .DESCRIPTION
 
  The Format-Ellipsis function splits a given string into segments by separator
  (directory separator by default) and tries to pack as much of them as possible
  into given width constraints.


 .PARAMETER InputString
 
  A string (usually a path) to be ellipsed.


 .PARAMETER Width
 
  Width constraint - maximum width available for output string.


 .PARAMETER Weighting
 
  The way how location of ellipsis inside a string will be determined.
  
  With option 'count' it will use number of segments on the left and on the right.
  
  With option 'length' or 'len' it will use number of characters on the left
  and on the right.
  
  Alias -by can be used.


 .PARAMETER Proportion
 
  Determines where to put ellipsis in an output string.
  
  Default value 0.5 mean that it will try to keep ellipsis as close to middle
  of the string as possible.
  
  Value 0.0 means beginning of the string and 1.0 means the end of the string.
  
  Note that this function prioritizes more efficient space usage to ellipsis
  placement precision and tries to fit as much whole segments as possible.
  Use -Strict parameter along with values 0.0 and 1.0 if you need the ellipsis
  strictly in the beginning or in the end of the string.


 .PARAMETER CutSegments
 
  The way how to fit remaining space when there is no more space for a whole segment.
  
  Option 'none' means that output string will be built only from complete
  segments, even if it end up shorter than requested width.
  
  Option 'left' (default) or 'right' means that part of a segment will be attached
  to corresponding side of output string to fit precisely to requested width.
  
  With option 'auto' part of a segment will be added in a way that brings
  an output string closer to required Proportion.
  
  Note that in presence of -Strict parameter 'left' and 'right' options are
  replaced with 'auto'.


 .PARAMETER Separator
 
  What separator will be used to split input string into segments.
  By default, directory separator is used.


 .PARAMETER EllipsisString
 
  What string will be substituted in place of omitted part of input string.
  By default, '...' is used.


 .PARAMETER Strict
 
  This function prioritizes more efficient space usage to ellipsis
  placement precision and tries to fit as much whole segments as possible.
  Use -Strict parameter along with values 0.0 and 1.0 if you need the ellipsis
  strictly in the beginning or in the end of the string.


 .EXAMPLE
   C:\PS> Format-Ellipsis "C:\Program Files\WindowsPowerShell\Modules\Pester" 40
   C:\Program Files\Windo...\Modules\Pester

 .EXAMPLE
   C:\PS> Format-Ellipsis "C:\Program Files\WindowsPowerShell\Modules\Pester" 40 -cut 'none'
   C:\Program Files\...\Modules\Pester
   # Only complete segments

 .EXAMPLE
   C:\PS> Format-Ellipsis "C:\Program Files\WindowsPowerShell\Modules\Pester" 40 -p 0.0 -Strict
   ...iles\WindowsPowerShell\Modules\Pester
   # Tail of a string

 .EXAMPLE
   C:\PS> Format-Ellipsis "a\a\a\a\a\a\a\bbbbbbbbb\bbbbbbbbb\bbbbbbbbb" 40 -by 'count'
   a\a\a\a...\bbbbbbbbb\bbbbbbbbb\bbbbbbbbb
   # Keep close to equal amount of segments on both sides


  .INPUTS
   This function accepts input string from pipeline.
  
  
  .OUTPUTS
   A string that was shortened to requested width or less.
  
  
  .LINK
   https://github.com/KillyMXI/PsEllipsisModule/ - GitHub repository
#>
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
