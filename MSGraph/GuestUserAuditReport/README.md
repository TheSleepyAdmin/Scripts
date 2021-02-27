This Script uses Graph API url's to query Guest users, sign-in activity logs and group membership, this script also requires that the 
MSAL.PS module is installed as this is used to generate the graph token use to access the diffrent graph urls.

https://www.powershellgallery.com/packages/MSAL.PS/4.21.0.1

The script is designed to work with certificates so this is a pre-req that Enterprise App for graph is setup, certificate is added and
installed on the local client. 

The script requires the follwoing details to be added 
TennantId (AzureAD) 
ClientID (from the Enterprise app)
ClientCert (Thumprint of the certficate that was uploaded to the Azure Enterprise app)
