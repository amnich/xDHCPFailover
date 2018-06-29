enum Ensure
{
    Absent
    Present
}

<#
   This resource manages the file in a specific path.
   [DscResource()] indicates the class is a DSC resource
#>

[DscResource()]
class xDhcpFailover
{
    <#
       The [DscProperty(Key)] attribute indicates the property is a
       key and its value uniquely identifies a resource instance.
       Defining this attribute also means the property is required
       and DSC will ensure a value is set before calling the resource.

       A DSC resource must define at least one key property.
    #>
    [DscProperty(Key)]
    [string]$UniqueKey

    <#
        This property indicates if the settings should be present or absent
        on the system. For present, the resource ensures the file pointed
        to by $Path exists. For absent, it ensures the file point to by
        $Path does not exist.

        The [DscProperty(Mandatory)] attribute indicates the property is
        required and DSC will guarantee it is set.

        If Mandatory is not specified or if it is defined as
        Mandatory=$false, the value is not guaranteed to be set when DSC
        calls the resource.  This is appropriate for optional properties.
    #>
    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    <#
       This property defines the fully qualified path to a file that will
       be placed on the system if $Ensure = Present and $Path does not
        exist.

       NOTE: This property is required because [DscProperty(Mandatory)] is
        set.
    #>

    [DscProperty(Mandatory)]
    [string] $Name

    [DscProperty(Mandatory)]
    [string] $ScopeId

    [DscProperty(Mandatory)]
    [string] $ActiveServer

    [DscProperty(Mandatory)]
    [string] $PartnerServer 

    <#
        This method is equivalent of the Set-TargetResource script function.
        It sets the resource to the desired state.
    #>
    [void] Set()
    {
        Write-Verbose -Message "Failover should be: $($this.Ensure)"
        if ($this.Ensure -eq [Ensure]::Present) {
            if ($this.ScopeId) {                                
                $failoverPresent = Get-DhcpServerv4Failover -ErrorAction Ignore | Where Name -eq $this.name 
                if ($failoverPresent){
                    Write-Verbose "$($this.name) present on $($this.ActiveServer). Adding scope $($this.scopeid)"
                    Add-DhcpServerv4FailoverScope -Name $this.Name -ScopeId $this.ScopeId
                }
                else{
                    Write-Verbose "Add $($this.name) on $($this.ActiveServer)"
                    Add-DhcpServerv4Failover -PartnerServer $this.PartnerServer -Name $this.Name -ServerRole Active -Force -ScopeId $this.ScopeId -AutoStateTransition $true 
                }
            }
        } 
        else {
            if ($this.ScopeId) {      
                Write-Verbose = "Remove scope $($this.ScopeId) from $($this.name) on $($this.ActiveServer)"
                Remove-DhcpServerv4FailoverScope -Name $this.name -ScopeId $this.ScopeId -ErrorAction Ignore
            }
        }
    }

    <#
        This method is equivalent of the Test-TargetResource script function.
        It should return True or False, showing whether the resource
        is in a desired state.
    #>
    [bool] Test()
    {
        Write-Verbose -Message "Option should be: $($this.Ensure)"
        $failoverPresentTest = Get-DhcpServerv4Failover -ScopeId $this.ScopeId -ErrorAction Ignore
        if ($failoverPresentTest){
            Write-Verbose -Message "Detected failover configuration for scope $($this.ScopeId)"
        }

        if ( $this.Ensure -eq [ensure]::Present) {
            if ( $failoverPresentTest | Where {$_.Name -eq $this.name -and $_.PartnerServer -eq $this.PartnerServer -and $_.Mode -eq 'HotStandby'}) {
                return $true
            }
            else {
                return $false
            }
        }
        else {
            if ($failoverPresentTest | Where {$_.Name -eq $this.name -and $_.PartnerServer -eq $this.PartnerServer -and $_.Mode -eq 'HotStandby'}) {
                return $false
            }
            else {
                return $true
            }
        }
    }

    <#
        This method is equivalent of the Get-TargetResource script function.
        The implementation should use the keys to find appropriate resources.
        This method returns an instance of this class with the updated key
         properties.
    #>
    [xDhcpFailover] Get()
    {
        $FailoverGet = Get-DhcpServerv4Failover -ScopeId $this.ScopeId -ErrorAction Ignore        
        $this.PartnerServer = $FailoverGet.PartnerServer
        $this.Name = $FailoverGet.Name
        return $this
    }
} 
