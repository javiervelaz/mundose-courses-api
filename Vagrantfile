# -*- mode: ruby -*-
# VM local del PIN: Ubuntu 24.04 en VirtualBox con Docker + Terraform.
# El repo queda montado en /vagrant; Terraform corre DENTRO de la VM.
#
#   vagrant up                      # crea y aprovisiona la VM (una vez)
#   vagrant ssh -c "bash /vagrant/scripts/local-up.sh <sha>"
#   vagrant ssh -c "bash /vagrant/scripts/local-down.sh"
#   vagrant destroy -f
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.hostname = "mundose-local"

  # Puertos accesibles desde Windows en localhost
  config.vm.network "forwarded_port", guest: 8080, host: 8081, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 9090, host: 9090, host_ip: "127.0.0.1"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "mundose-local"
    vb.cpus   = 2
    vb.memory = 4096
  end

  config.vm.provision "shell", path: "scripts/provision-vm.sh"
end
