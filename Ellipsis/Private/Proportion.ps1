
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
