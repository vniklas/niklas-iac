# Azure Landing Zone Deployment Script (PowerShell)
# This script deploys the Azure Landing Zone using Bicep templates

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-landingzone-prod-001",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "main.bicep",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "parameters/main.parameters.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$DeploymentName = "landingzone-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "🚀 Starting Azure Landing Zone Deployment" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Check if Azure PowerShell is installed
try {
    Import-Module Az -Force
    Write-Host "✅ Azure PowerShell module loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure PowerShell is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Run: Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    $context = Get-AzContext
    if ($null -eq $context) {
        throw "Not logged in"
    }
    Write-Host "📋 Current subscription: $($context.Subscription.Name)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Not logged in to Azure. Starting login process..." -ForegroundColor Yellow
    Connect-AzAccount
    $context = Get-AzContext
    Write-Host "✅ Logged in successfully" -ForegroundColor Green
}

# Prompt for subscription change if needed
$changeSubscription = Read-Host "Do you want to change the subscription? (y/N)"
if ($changeSubscription -eq "y" -or $changeSubscription -eq "Y") {
    Write-Host "Available subscriptions:" -ForegroundColor Yellow
    Get-AzSubscription | Format-Table Name, Id, State
    $subscriptionId = Read-Host "Enter subscription ID"
    Set-AzContext -SubscriptionId $subscriptionId
    $context = Get-AzContext
    Write-Host "✅ Switched to subscription: $($context.Subscription.Name)" -ForegroundColor Green
}

# Create resource group if it doesn't exist
Write-Host "🏗️  Checking resource group..." -ForegroundColor Yellow
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $resourceGroup) {
    Write-Host "⚠️  Resource group '$ResourceGroupName' does not exist. Creating..." -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    Write-Host "✅ Resource group created successfully" -ForegroundColor Green
} else {
    Write-Host "✅ Resource group '$ResourceGroupName' already exists" -ForegroundColor Green
}

# Validate the template
Write-Host "🔍 Validating Bicep template..." -ForegroundColor Yellow
try {
    $validationResult = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParametersFile
    
    if ($validationResult.Count -eq 0) {
        Write-Host "✅ Template validation successful" -ForegroundColor Green
    } else {
        Write-Host "❌ Template validation failed:" -ForegroundColor Red
        $validationResult | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }
} catch {
    Write-Host "❌ Template validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Deploy the template
Write-Host "🚀 Starting deployment..." -ForegroundColor Yellow
Write-Host "Deployment name: $DeploymentName"
Write-Host "Resource group: $ResourceGroupName"
Write-Host "Template file: $TemplateFile"
Write-Host "Parameters file: $ParametersFile"
Write-Host ""

try {
    if ($WhatIf) {
        Write-Host "🔍 Running What-If analysis..." -ForegroundColor Yellow
        $whatIfResult = New-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -TemplateFile $TemplateFile `
            -TemplateParameterFile $ParametersFile `
            -Name $DeploymentName `
            -WhatIf
        
        Write-Host "✅ What-If analysis completed" -ForegroundColor Green
        return
    }
    
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParametersFile `
        -Name $DeploymentName `
        -Verbose
    
    Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Show deployment outputs
    Write-Host "📋 Deployment Outputs:" -ForegroundColor Yellow
    if ($deployment.Outputs) {
        $deployment.Outputs | Format-Table Key, @{Name="Value"; Expression={$_.Value.Value}}
    } else {
        Write-Host "No outputs available" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Get deployment details for troubleshooting
    Write-Host "📋 Checking deployment status..." -ForegroundColor Yellow
    try {
        $deploymentDetails = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $DeploymentName
        if ($deploymentDetails.ProvisioningState -eq "Failed") {
            Write-Host "Deployment failed with the following details:" -ForegroundColor Red
            $deploymentDetails | Format-List
        }
    } catch {
        Write-Host "Could not retrieve deployment details" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "✅ Azure Landing Zone deployment completed successfully!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
