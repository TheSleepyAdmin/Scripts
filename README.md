# Scripts

This is a PowerShell script to check DFS replication on domain controlers. I was having issue with our AD DFS replication. We where constantly getting EventID 2213 and this required manual intervention to run a WMI fix to resume replication. This script run agaist the domains that are set in the domains variable. This then check's for each domain controller in the AD forest and run's Get-WmiObject to check DFS replication. If the status is not equal to 4 the script will run the ResumeReplication method from WMI. This is designed for enviorments that use DFS-R for sysvol replication not FRS replication. 

Status codes for DFS are below.

0
Uninitialized
1	Initialized
2	Initial synchronization
3	Auto recovery
4	Normal
5	In error state
6	Disabled
7	Unknown
 

 Change the below variable with list of AD domain's to be checked.
