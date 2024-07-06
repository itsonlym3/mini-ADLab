# -*- mode: ruby -*-
# vi: set ft=ruby :

$shell_script = <<-SCRIPT
  Write-Host "Hey, this happened after the restart!"
  $adminPassword = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
  $creds = New-Object System.Management.Automation.PSCredential("pentest\\Administrator", $adminPassword)

  try {
    Install-ADDSDomainController `
      -DomainName "pentest.local" `
      -Credential $creds `
      -SiteName "Default-First-Site-Name" `
      -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
      -InstallDns `
      -Force `
      -ErrorAction Stop
    Write-Host "DEBUG: ADDS Domain Controller installation succeeded"
  } catch {
    Write-Host "ERROR: ADDS Domain Controller installation failed"
    Write-Host $_.Exception.Message
    exit 1
  }
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "jborean93/WindowsServer2022"

  # Primary Domain Controller
  config.vm.define "dc1" do |dc1|
    dc1.vm.hostname = "dc1"
    dc1.vm.network "private_network", ip: "192.168.56.10"
    dc1.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
    end

  # set provider and show each vm as it's spun up
  config.vm.provider "virtualbox" do |v|
    v.gui = true
  end

    dc1.vm.provision "shell", inline: <<-SHELL
      Write-Host "DEBUG: Enabling Administrator and setting password"
      net user Administrator P@ssw0rd123 /active:yes /expires:never
      Write-Host "DEBUG: Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
      Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
      Write-Host "DEBUG: Install-ADDSForest -DomainName pentest.local"
      Install-ADDSForest -DomainName "pentest.local" -DomainNetBiosName "PENTEST" -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) -InstallDNS -Force
      Write-Host "DEBUG: Waiting for AD services to fully start"
      Start-Sleep -Seconds 5
    SHELL
  end


  # Secondary Domain Controller
  config.vm.define "dc2" do |dc2|
    dc2.vm.hostname = "dc2"
    dc2.vm.network "private_network", ip: "192.168.56.11"
    dc2.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
    end

    dc2.vm.provision "shell", inline: <<-SHELL
      Write-Host "DEBUG: Enabling Administrator and setting password"
      net user Administrator P@ssw0rd123 /active:yes /expires:never
      Write-Host "DEBUG: Setting DNS server to DC1"
      Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 192.168.56.10
      Write-Host "Sleeping for 15s..."
      Start-Sleep -Seconds 15

      Write-Host "DEBUG: Installing AD-Domain-Services"
      Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    SHELL

    dc2.vm.provision :windows_domain do |domain|
      domain.domain = "pentest.local"
      #domain.computer_name = "dc2"
      domain.username = "Administrator"
      domain.password = "P@ssw0rd123"
      domain.unsecure = false
    end

    # Confirm that this will run after the reload from the domain provisioner!
    dc2.vm.provision "shell", inline: $shell_script, name: "Post-Domain Join Script"
    dc2.vm.provision "reload"
  end

# Configure the Windows 10 client
config.vm.define "win10" do |win10|
  win10.vm.box = "tjbwin10"
  win10.vm.hostname = "win10"
  win10.vm.network "private_network", ip: "192.168.56.15"

  # Specify WinRM as the communicator
  win10.vm.communicator = "winrm"

  # Provider-specific configurations for VirtualBox
  win10.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end

  # Copy the credentials XML file to the guest machine
  win10.vm.provision "file", source: "./credentials.xml", destination: "C:\\vagrant\\credentials.xml"

  # Provisioning script for Windows 10
  win10.vm.provision "shell", inline: <<-SHELL
    Write-Host "DEBUG: Setting DNS server to DC1"
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.56.10

    Write-Host "Sleeping for 5s..."
    Start-Sleep -Seconds 5

    Write-Host "DEBUG: Provisioning Windows 10 client"
    $domainCredential = Import-CliXml -Path "C:\\vagrant\\credentials.xml"
    Add-Computer -DomainName "pentest.local" -Credential $domainCredential -Restart
  SHELL
end
end

