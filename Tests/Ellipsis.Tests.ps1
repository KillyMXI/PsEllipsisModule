
Remove-Module "Ellipsis" -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\Ellipsis\Ellipsis.psm1" -Force

function Fix-Separator # just in case separator is not a backslash (PowerShell on Linux)
{
    return $Input.Replace('\', [IO.Path]::DirectorySeparatorChar)
}

Describe "Format-Ellipsis" {
    Context "Availability" {
        It "should be available" {
            & { Get-Command Format-Ellipsis } | Should Not Be $null
        }
        It "should be of type FunctionInfo" {
            & { Get-Command Format-Ellipsis } | Should BeOfType System.Management.Automation.FunctionInfo
        }
    }
    Context "Basic function" {
        $width = 10
        $shorter = 'aaaaa'
        $longer = 'aaaaaaaaaaaaaaaaa'
        It "should return short string unchanged" {
            Format-Ellipsis $shorter $width | Should Be $shorter
        }
        It "should shorten long string to provided width" {
            Format-Ellipsis $longer $width | Should Be 'aaaaaaa...'
        }
        It "should accept input from pipeline" {
            & { $longer | Format-Ellipsis -w $width } | Should Be 'aaaaaaa...'
        }
    }
    Context "Weighting and proportion" {
        $string1 = 'a\a\a\a\a\a\a\a\a\a\a\a\bbbbbbbbbbb\a' | Fix-Separator
        $string2 = 'a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a' | Fix-Separator
        $string3 = 'a\bbbbbbbbbbb\a\a\a\a\a\a\a\a\a\a\a\a' | Fix-Separator
        $width = 27
        It "should do weighting by count" {
            Format-Ellipsis $string3 $width -by 'count' | Should Be ('a\bbbbbbbbbbb\a\a\...\a\a\a' | Fix-Separator)
        }
        It "should do weighting by length" {
            Format-Ellipsis $string3 $width -by 'len' | Should Be ('a\bbbbbbbbbbb\...\a\a\a\a\a' | Fix-Separator)
        }
        It "should do proportions (1)" {
            Format-Ellipsis $string2 $width -p 0.3 | Should Be ('a\a\a\a\...\a\a\a\a\a\a\a\a' | Fix-Separator)
        }
        It "should do proportions (2)" {
            Format-Ellipsis $string2 $width -p 0.8 | Should Be ('a\a\a\a\a\a\a\a\a\...\a\a\a' | Fix-Separator)
        }
        It "should do strictly head" {
            Format-Ellipsis $string1 $width -p 1.0 -Strict | Should Be ('a\a\a\a\a\a\a\a\a\a\a\a\...' | Fix-Separator)
        }
        It "should do strictly tail" {
            Format-Ellipsis $string3 $width -p 0.0 -Strict | Should Be ('...\a\a\a\a\a\a\a\a\a\a\a\a' | Fix-Separator)
        }
    }
    Context "Cut segments" {
        $string3 = 'a\a\a\bbbbbbbbbbbbbbbbbbbbb\c\c\c\c' | Fix-Separator
        $string4 = 'a\a\a\a\bbbbbbbbbbbbbbbbbbbbb\c\c\c' | Fix-Separator
        $width = 25
        It "should use only complete segments if -cut 'none'" {
            Format-Ellipsis $string3 $width -cut 'none' | Should Be ('a\a\a\...\c\c\c\c' | Fix-Separator)
        }
        It "should extend left side if -cut 'left'" {
            Format-Ellipsis $string3 $width -cut 'left' | Should Be ('a\a\a\bbbbbbbb...\c\c\c\c' | Fix-Separator)
        }
        It "should extend right side if -cut 'right'" {
            Format-Ellipsis $string3 $width -cut 'right' | Should Be ('a\a\a\...bbbbbbbb\c\c\c\c' | Fix-Separator)
        }
        It "should extend closer to proportion if -cut 'auto' (1)" {
            Format-Ellipsis $string3 $width -p 0.5 -cut 'auto' | Should Be ('a\a\a\bbbbbbbb...\c\c\c\c' | Fix-Separator)
        }
        It "should extend closer to proportion if -cut 'auto' (2)" {
            Format-Ellipsis $string4 $width -p 0.5 -cut 'auto' | Should Be ('a\a\a\a\...bbbbbbbb\c\c\c' | Fix-Separator)
        }
        It "should extend left side by default" {
            Format-Ellipsis $string4 $width | Should Be ('a\a\a\a\bbbbbbbb...\c\c\c' | Fix-Separator)
        }
    }
    Context "Separators and ellipsis strings" {
        $string5 = 'a/a/b\b\c c d-d-e;e;e'
        $string6 = 'aaaaaaaaaaaaaaaaa'
        $width = 15
        It "should do separators (1)" {
            Format-Ellipsis $string5 $width -cut 'none' -s '/' | Should Be 'a/a/...'
        }
        It "should do separators (2)" {
            Format-Ellipsis $string5 $width -cut 'none' -s ' ' | Should Be 'a/a/b\b\c c ...'
        }
        It "should do ellipsis string" {
            Format-Ellipsis $string6 $width -e '*****' | Should Be 'aaaaaaaaaa*****'
        }
    }
}
