# https://www.visualstudio.com/integrate/api/build/builds
# https://www.simple-talk.com/sql/database-delivery/writing-build-vnext-tasks-for-visual-studio-online/
# https://msdn.microsoft.com/Library/vs/alm/Build/scripts/variables
# https://github.com/Microsoft/tfs-cli/blob/master/docs/configureBasicAuth.md


param(
    [string]$tfsCollectionConnection,
    [string]$Project,
    [string]$BuildDefinition,
    [switch]$debug=$false
    )

Write-Verbose "Importing modules"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function GetEndpointData
{
	param([string][ValidateNotNullOrEmpty()]$tfsCollectionConnection)

	$serviceEndpoint = Get-ServiceEndpoint -Context $distributedTaskContext -Name $tfsCollectionConnection

	if (!$serviceEndpoint)
	{
		throw "A Connected Service with name '$tfsCollectionConnection' could not be found.  Ensure that this Connected Service was successfully provisioned using the services tab in the Admin UI."
	}

    return $serviceEndpoint
}
Write-Verbose "Entering TFSBuildChain.ps1" -Verbose
Write-Verbose "TFS Connection = $tfsCollectionConnection" -Verbose
Write-Verbose "Target Project = $Project" -Verbose
Write-Verbose "Build Definition = $BuildDefinition" -Verbose


$API_VERSION = "2.0";
$currentProject = $env:SYSTEM_TEAMPROJECT;

Write-Verbose "Current Collection: $currentCollection"
Write-Verbose "Current Project: $currentProject"

Write-Verbose "Using service endpoint URL"
$serviceEndpoint = GetEndpointData $tfsCollectionConnection
$collectionUri = $($serviceEndpoint.Url)

write-verbose "Using Collection Uri $collectionUri with Project $Project and Build Defnition $BuildDefinition"

$restUrl = "$collectionUri/$Project/_apis/build/definitions?api-version=$API_VERSION";
write-debug $restUrl

$pass =  ConvertTo-SecureString  $($serviceEndpoint.Authorization.Parameters.Password) -AsPlainText -Force;
$user = $($serviceEndpoint.Authorization.Parameters.Username);
write-debug $user
$superCredentials = New-Object System.Management.Automation.PSCredential($user, $pass)

write-debug "Getting list of available builds"
$builds =  Invoke-RestMethod -Method GET -Uri $restUrl -Credential $superCredentials 

if($builds.count -eq 0) {
    Write-Verbose "Could not find any builds!"
    exit -1;
}

write-verbose "Searching for build ..."
foreach($run in $builds.value) {
    
    if($run.name -eq $BuildDefinition -or $run.id -eq $BuildDefinition)
    {
        $BuildDefinitionId = $run.id;
        break;
    }
}
write-debug "After search for $BuildDefinition => $BuildDefinitionId"
if( ! $BuildDefinitionId ) {
    Write-Verbose "Could not find $BuildDefintion"
    exit -2;
}

$restTriggerBody = 
"{ 
 ""definition"": {
    ""id"": $BuildDefinitionId
    }   
}";

$restTriggerUri = "$collectionUri/$Project/_apis/build/builds?api-version=$API_VERSION"
write-debug "triggering $restTriggerUri"
$trigger = Invoke-RestMethod  -ContentType "application/json" -Method Post -Uri $restTriggerUri -Credential $superCredentials -Body $restTriggerBody

 