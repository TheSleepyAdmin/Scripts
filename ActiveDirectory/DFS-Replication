#------------------------------------------------------------------------------  
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT  
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT  
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS  
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR   
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.  
#  
#------------------------------------------------------------------------------  
# Author: Geoff Phillis  
# Version: 1.0 
#------------------------------------------------------------------------------  
# AD_DFS replication  
# This script will run against each domain set in the Domains variable and 
# if state does not equal normal status code will try to run fix command to
# resume replication
#------------------------------------------------------------------------------ 
# Pre Reqs: 
# This needs remote WMI port open to run get-wmiobject 
# ------------------------------------------------------------------------------  
###########################################################################################

$domains = "Lab.local"
foreach ($domain in $domains){
$DCs = (Get-ADForest $domain).GlobalCatalogs
foreach ($DC in $DCs){
$DCCheck = Get-WmiObject -ComputerName $DC -Namespace "root\microsoftdfs" -Class dfsrreplicatedfolderinfo  | 
Select-Object -Property PSComputerName, Replicationgroupname, Replicatedfoldername, State
$DCCheck
if ($DCCheck.State -ne "4")
{
Write-Warning "AD DFS replication is not working on $DC will run repair command"
$DFSRep = Get-WmiObject -ComputerName $DC -Namespace "root\microsoftdfs" -Class dfsrVolumeConfig
$DFSRep.ResumeReplication()
}
        }
    }
