# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end
  
  # Imagen por defecto
  box = 'ubuntu/jammy64'
  
  # Si se ejecuta sobre macOS se configura otra imagen
  if Vagrant::Util::Platform.darwin? 
    box = "bento/ubuntu-22.04-arm64"
  else
    config.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y virtualbox-guest-x11 python3-pip"
    config.vm.provision "shell", inline: <<-SHELL
      sudo pip3 install flask
      cd /vagrant
      sudo chmod +x /vagrant/app.py
      sudo python3 app.py
    SHELL
  end

  # Con esto le indicamos a Vagrant que vaya al directorio de "cajas" (boxes) que contiene su Atlas e instale un
  # Ubuntu 64 bits mediante el gestor de maquinas virtuales VirtualBox
  # El directorio completo de boxes se puede ver en la siguiente URL https://app.vagrantup.com/boxes/search
  config.vm.box = box

  # Redirecciono puertos desde la maquina virtual a la maquina real. Por ejemplo
  # del puerto 80 (web) de la maquina virtual con Debian se podrá acceder a través
  # del puerto 8080 de nuestro navegador.
  # Esto se realiza para poder darle visibilidad a los puertos de la maquina virtual
  # y además para que no se solapen los puertos con los de nuestra equipo en el caso de que
  # ese número de puerto este en uso.
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Permite descargas con certificados vencidos o por http
  config.vm.box_download_insecure = true

  # Configuración del nombre de maquina
  config.vm.hostname = "utn-devops-grupo2-u1.localhost"
  config.vm.boot_timeout = 3600

  # Configuro la cantidad de memoria ram de la VM para el proveedor VirtualBox
  config.vm.provider "virtualbox" do |v|
    v.name = "utn-devops-vagrant-grupo2-u1-ubuntu"
    v.memory = "1024"
  end

  # Mapeo de directorios que se comparten entre la maquina virtual y nuestro equipo. En este caso es
  # el propio directorio donde está el archivo  y el directorio "/vagrant" dentro de la maquina virtual.
  config.vm.synced_folder ".", "/vagrant"

  # Configuro la cantidad de memoria ram de la VM para el proveedor VMware
  config.vm.provider "vmware_desktop" do |vm|
    vm.memory = "1024"
  end
end
