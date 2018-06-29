# xDHCPFailover

DSC Resource to configure the DHCP Failover in HotStandby

Example usage in DSC.
Sets the curent node as Active.


	Configuration DhcpServer
	{
	    param (
		[Parameter(Mandatory)]
		[PSCredential]$Credential
	    )


	    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	    Import-DscResource -ModuleName (@{ModuleName='DHCPFailover'; RequiredVersion='0.1'} )

	    Node $AllNodes.Where{$_.Role -eq "DhcpServer"}.NodeName
	    {
		# Certificate Management
		LocalConfigurationManager 
		{
		    CertificateId = $node.Thumbprint
		}

			foreach ($scope in $node.Scopes) {
				DhcpFailover "failover_$($scope.ScopeId)"
				{
				  Ensure = $scope.FailoverEnsure
				  UniqueKey = "$($scope.ScopeId)_$($scope.FailoverName)"
				  ScopeID = $scope.ScopeID
				  Name = $scope.FailoverName
				  ActiveServer = $node.NodeName
				  PartnerServer = $scope.FailoverPartner
				  PsDscRunAsCredential = $Credential
				}
			}
		}
	}


Example Configuration data for DSC

	@{
	    AllNodes = @(
		@{
		    NodeName = "*"            
		}
		@{
		    NodeName = "MAINDHCP01"
            
		    CertificateFile = "C:\Cert\MAINDHCP01.cer"
		    Thumbprint = "991A3C7FAEE90ABC18A8931453AECAC4FF7555EE"            
		    Role = "DhcpServer"
		    Scopes = @(
			@{
				ScopeId = "192.168.0.0"                    
				FailoverEnsure = "Present"
				FailoverName = "MY_Failover"
				FailoverPartner = "BACKUPDHCP01"
			}                
		    )            
        	}    
     )
	}
