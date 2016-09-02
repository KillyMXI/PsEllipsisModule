
# tests for non-exported functions

$Private  = Get-ChildItem $PSScriptRoot\..\Ellipsis\Private\*.ps1 -ErrorAction SilentlyContinue

Foreach($import in $Private)
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

Describe "Proportion" {
    Context "empty sources - both numbers are zero" {
        It "should return 0.5 if both numbers are zero" {
            Proportion 0.0 0.0 | Should Be 0.5
        }
    }
    Context "nonempty sources - at least one number is nonzero" {
        It "should return 0.0 if first number is zero" {
            Proportion 0.0 5.0 | Should Be 0.0
        }
        It "should return 1.0 if second number is zero" {
            Proportion 5.0 0.0 | Should Be 1.0
        }
        It "should return a/(a+b) in any other case" {
            $a = 10.0
            $b = $a*3
            Proportion $a $b | Should Be 0.25
            $a = 15.0
            $b = $a/3
            Proportion $a $b | Should Be 0.75
        }
    }
}

Describe "Metrics" {
    Context "CountMetric" {
        It "should return number of strings in array (nonempty)" {
            CountMetric "a","b","c" | Should Be 3
        }
        It "should return number of strings in array (empty strings)" {
            CountMetric "","","" | Should Be 3
        }
        It "should return zero for empty array" {
            CountMetric @() | Should Be 0
        }
    }
    Context "SummaryLengthMetric" {
        It "should return number of characters in all strings from array (nonempty)" {
            SummaryLengthMetric "a","bbb","ccccccc" | Should Be 11
        }
        It "should return zero for array of empty strings" {
            SummaryLengthMetric "","","" | Should Be 0
        }
        It "should return zero for empty array" {
            SummaryLengthMetric @() | Should Be 0
        }
    }
    Context "SummaryLengthMetric with correction" {
        It "should return number of characters in all strings plus correction amount per string" {
            SummaryLengthMetric "a","bbb","ccccccc" 5 | Should Be (11 + 5 * 3)
        }
        It "should return zero for array of empty strings plus correction amount per string" {
            SummaryLengthMetric "","","" 5 | Should Be (0 + 5 * 3)
        }
        It "should return zero for empty array" {
            SummaryLengthMetric @() 5 | Should Be 0
        }
    }
}