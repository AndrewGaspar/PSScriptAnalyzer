﻿Import-Module -Verbose PSScriptAnalyzer
$sa = Get-Command Get-ScriptAnalyzerRule
$directory = Split-Path -Parent $MyInvocation.MyCommand.Path
$singularNouns = "PSUseSingularNouns"
$approvedVerbs = "PSUseApprovedVerbs"
$dscIdentical = "PSDSCUseIdenticalParametersForDSC"

Describe "Test available parameters" {
    $params = $sa.Parameters
    Context "Name parameter" {
        It "has a Name parameter" {
            $params.ContainsKey("Name") | Should Be $true
        }
        
        It "accepts string" {
            $params["Name"].ParameterType.FullName | Should Be "System.String[]"
        }
    }

    Context "RuleExtension parameters" {
        It "has a RuleExtension parameter" {
            $params.ContainsKey("CustomizedRulePath") | Should Be $true
        }

        It "accepts string array" {
            $params["CustomizedRulePath"].ParameterType.FullName | Should Be "System.String[]"
        }
    }

}

Describe "Test Name parameters" {
    Context "When used correctly" {
        It "works with 1 name" {
            $rule = Get-ScriptAnalyzerRule -Name $singularNouns
            $rule.Count | Should Be 1
            $rule[0].Name | Should Be $singularNouns
        }

        It "works for DSC Rule" {
            $rule = Get-ScriptAnalyzerRule -Name $dscIdentical
            $rule.Count | Should Be 1
            $rule[0].Name | Should Be $dscIdentical
        }

        It "works with 3 names" {
            $rules = Get-ScriptAnalyzerRule -Name $approvedVerbs, $singularNouns
            $rules.Count | Should Be 2
            ($rules | Where-Object {$_.Name -eq $singularNouns}).Count | Should Be 1
            ($rules | Where-Object {$_.Name -eq $approvedVerbs}).Count | Should Be 1
        }
    }

    Context "When used incorrectly" {
        It "1 incorrect name" {
            $rule = Get-ScriptAnalyzerRule -Name "This is a wrong name"
            $rule.Count | Should Be 0
        }

        It "1 incorrect and 1 correct" {
            $rule = Get-ScriptAnalyzerRule -Name $singularNouns, "This is a wrong name"
            $rule.Count | Should Be 1
            $rule[0].Name | Should Be $singularNouns
        }
    }
}

Describe "Test RuleExtension" {
    $community = "CommunityAnalyzerRules"
    $measureRequired = "Measure-RequiresModules"
    Context "When used correctly" {
        It "with the module folder path" {
            $ruleExtension = Get-ScriptAnalyzerRule -CustomizedRulePath $directory\CommunityAnalyzerRules | Where-Object {$_.SourceName -eq $community}
            $ruleExtension.Count | Should Be 12
        }

        It "with the psd1 path" {
            $ruleExtension = Get-ScriptAnalyzerRule -CustomizedRulePath $directory\CommunityAnalyzerRules\CommunityAnalyzerRules.psd1 | Where-Object {$_.SourceName -eq $community}
            $ruleExtension.Count | Should Be 12

        }

        It "with the psm1 path" {
            $ruleExtension = Get-ScriptAnalyzerRule -CustomizedRulePath $directory\CommunityAnalyzerRules\CommunityAnalyzerRules.psm1 | Where-Object {$_.SourceName -eq $community}
            $ruleExtension.Count | Should Be 12
        }

        It "with Name of a built-in rules" {
            $ruleExtension = Get-ScriptAnalyzerRule -CustomizedRulePath $directory\CommunityAnalyzerRules\CommunityAnalyzerRules.psm1 -Name $singularNouns
            $ruleExtension.Count | Should Be 1
            $ruleExtension[0].Name | Should Be $singularNouns
        }

        It "with Names of built-in, DSC and non-built-in rules" {
            $ruleExtension = Get-ScriptAnalyzerRule -CustomizedRulePath $directory\CommunityAnalyzerRules\CommunityAnalyzerRules.psm1 -Name $singularNouns, $measureRequired, $dscIdentical
            $ruleExtension.Count | Should be 3
            ($ruleExtension | Where-Object {$_.Name -eq $measureRequired}).Count | Should Be 1
            ($ruleExtension | Where-Object {$_.Name -eq $singularNouns}).Count | Should Be 1
            ($ruleExtension | Where-Object {$_.Name -eq $dscIdentical}).Count | Should Be 1
        }
    }

    Context "When used incorrectly" {
        It "file cannot be found" {
            $wrongFile = Get-ScriptAnalyzerRule -CustomizedRulePath "This is a wrong rule" 3>&1
            ($wrongFile  | Select-Object -First 1) | Should Match "Cannot find rule extension 'This is a wrong rule'."
            ($wrongFile | Where-Object {$_.Name -eq $singularNouns}).Count | Should Be 1
        }

    }
}