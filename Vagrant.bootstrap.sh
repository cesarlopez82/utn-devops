#!/bin/bash
echo "#########################################################################"
echo "########################## INICIANDO SCRIPT #############################"
echo "#########################################################################"
echo "-------------------------------------------------------------------------"

# Verifico si ya se ha ejecutado el script
if [ ! -f /var/vagrant_bootstrap_completed ]; then
    echo "Running Vagrant bootstrap script..."
    # Ejecutar el script
    touch /var/vagrant_bootstrap_completed
else
    echo "Saliendo del script."
    #  exit 0
fi

# Verifico si python3-pip esta instalado
echo "-----------------------------> VERIFICANDO si python3-pip esta instalado"

if dpkg -s python3-pip &> /dev/null; then
    # Uninstall python3-pip
    echo "desinstalando python3-pip..."
    sudo apt-get remove python3-pip -y
    echo "python3-pip se ha desintalado."
else
    echo "python3-pip no está instalado."
fi

#Actualizo los paquetes disponibles de la VM
echo "-----------------------------> ACTUALIZANDO apt-get update -y"
sudo apt-get update -y
#Aprovisionamiento de software
echo "-----------------------------> INSTALANDO PAQUETES BASE"

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common linux-image-extra-virtual-hwe-$(lsb_release -r |awk  '{ print $2 }') linux-image-extra-virtual

# Directorio para los archivos de la base de datos MySQL. El servidor de la base de datos
# es instalado mediante una imagen de Docker. Esto está definido en el archivo
# docker-compose.yml
if [ ! -d "/var/db/mysql" ]; then
	sudo mkdir -p /var/db/mysql
fi

# Muevo el archivo de configuración de firewall al lugar correspondiente
if [ -f "/tmp/ufw" ]; then
	sudo mv -f /tmp/ufw /etc/default/ufw
fi

# Muevo el archivo hosts. En este archivo esta asociado el nombre de dominio con una dirección
# ip para que funcione las configuraciones de Puppet
if [ -f "/tmp/etc_hosts.txt" ]; then
	sudo mv -f /tmp/etc_hosts.txt /etc/hosts
fi

##Swap
##Genero una partición swap. Previene errores de falta de memoria
if [ ! -f "/swapdir/swapfile" ]; then
	sudo mkdir /swapdir
	cd /swapdir
	sudo dd if=/dev/zero of=/swapdir/swapfile bs=1024 count=2000000
 	sudo chmod 0600 /swapdir/swapfile
	sudo mkswap -f  /swapdir/swapfile
	sudo swapon swapfile
	echo "/swapdir/swapfile       none    swap    sw      0       0" | sudo tee -a /etc/fstab /etc/fstab
	sudo sysctl vm.swappiness=10
	echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf
fi

##################################################################
##################################################################
################################################################## 
# Configuración applicación
# ruta de la aplicación

# root path
APP_ROOT="/opt/app"
# ruta de la aplicación
APP_PATH="$APP_ROOT/utn-devops-app"
# ruta al directorio docker
DOCKER_PATH="$APP_PATH/docker"
# git app repository
GIT_APP_REPO="https://github.com/cesarlopez82/utn-devops-app.git"

# Verifico que exista el root path para la app
echo "-----------------------------> VERIFICANDO $APP_ROOT"
if [  -d  $APP_ROOT ]; then
    echo "-----------------------------> Creando dir $APP_ROOT"
	sudo mkdir -p $APP_ROOT
fi

# Verificar si el repositorio ya ha sido clonado
echo "-----------------------------> VERIFICANDO $APP_PATH/.git"
if [ -d "$APP_PATH/.git" ]; then
    echo "-----------------------------> ACTUALIZANDO!"
    echo "El repositorio ya ha sido clonado. Actualizando..."
    cd $APP_PATH
    sudo git reset --hard HEAD
    sudo git pull origin main
else
    # Si el directorio .git no existe, clonar el repositorio
    echo "-----------------------------> CLONANDO!"
    echo "Clonando el repositorio..."
    sudo git clone $GIT_APP_REPO $APP_PATH
fi

cd $APP_PATH

##################################################################
######## Instalacion de DOCKER - Unidad 2########
#
# Esta instalación de docker es para demostrar el aprovisionamiento
# complejo mediante Vagrant. La herramienta Vagrant por si misma permite
# un aprovisionamiento de container mediante el archivo Vagrantfile. A fines
# del ejemplo que se desea mostrar en esta unidad que es la instalación mediante paquetes del
# software Docker este ejemplo es suficiente, para un uso más avanzado de Vagrant
# se puede consultar la documentación oficial en https://www.vagrantup.com
#

echo "-----------------------------> VERIFICANDO Instalacion de docker"
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed."
    echo "-----------------------------> INSTALANDO docker"
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

	##Configuramos el repositorio
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	sudo chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	
	#Actualizo los paquetes con los nuevos repositorios
	sudo apt-cache policy docker-ce
	sudo apt-get update -y
	#Instalo docker desde el repositorio oficial
	sudo apt-get -y  install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
	
	#Lo configuro para que inicie en el arranque
	sudo systemctl enable docker    
else
    echo "Docker is installed."
    # Obtener la versión de Docker
    docker_version=$(docker --version | awk '{print $3}')
    echo "-----------------------------> Docker version: $docker_version"
fi


echo "-----------------------------> VERIFICANDO $DOCKER_PATH"
if [ -d "$DOCKER_PATH" ]; then
    echo "-----------------------------> VERIFICANDO docker-compose.yml"
    if [ -f "$DOCKER_PATH/docker-compose.yml" ]; then
        echo "Archivo docker-compose.yml encontrado!"
        #cp $APP_PATH/app.py $DOCKER_PATH
        cd $DOCKER_PATH
        echo "-----------------------------> DESTRUYENDO CONTENEDORES"
        sudo docker-compose down
        # Verificar que docker-compose down haya terminado correctamente
        if [ $? -eq 0 ]; then
            echo "docker-compose down ha terminado correctamente. Iniciando docker-compose up -d --build..."            
        else
            echo "ERROR: docker-compose down -v ha fallado. No se puede continuar."
        fi
        # Recreando contenedores.
        echo "-----------------------------> RECREANDO CONTENEDORES"
        docker-compose up -d --build
                
    else
        echo "WARNING: El archivo docker-compose.yml no existe."
    fi
else
    echo "WARNING: No existe el directorio $DOCKER_PATH"
fi

##################################################################
######## Instalacion de PUPPET - Unidad 3########
#
# Esta instalación de PUPPET es para demostrar el aprovisionamiento
# complejo mediante Vagrant.

echo "-----------------------------> INICIO DE INSTALACIÓN PUPPET"

#Directorios
PUPPET_DIR="/etc/puppet"
ENVIRONMENT_DIR="${PUPPET_DIR}/code/environments/production"
PUPPET_MODULES="${ENVIRONMENT_DIR}/modules"

if [ ! -x "$(command -v puppet)" ]; then
  #configuración de repositorio
  sudo add-apt-repository universe -y
  sudo add-apt-repository multiverse -y
  sudo apt-get update
  sudo apt install -y puppet-master
  
  #### Instalacion puppet agent
  sudo apt install -y puppet

  # Esto es necesario en entornos reales para posibilitar la sincronizacion
  # entre master y agents
  sudo timedatectl set-timezone America/Argentina/Buenos_Aires
  sudo apt-get -y install ntp

  # Muevo el archivo de configuración de Puppet al lugar correspondiente
  sudo mv -f /tmp/puppet-master.conf $PUPPET_DIR/puppet.conf

  # elimino certificados de que se generan en la instalación.
  # no nos sirven ya que el certificado depende del nombre que se asigne al maestro
  # y en este ejemplo se modifico.
  sudo rm -rf /var/lib/puppet/ssl

  # Agrego el usuario puppet al grupo de sudo, para no necesitar password al reiniciar un servicio
  sudo usermod -a -G sudo,puppet puppet

  # Estructura de directorios para crear el entorno de Puppet
  sudo mkdir -p $ENVIRONMENT_DIR/{manifests,modules,hieradata}
  sudo mkdir -p $PUPPET_MODULES/docker_install/{manifests,files}

  # Estructura de directorios para crear el modulo de Jenkins
  sudo mkdir -p $PUPPET_MODULES/jenkins/{manifests,files}

  # muevo los archivos que utiliza Puppet
  sudo mv -f /tmp/site.pp $ENVIRONMENT_DIR/manifests #/etc/puppet/manifests/
  sudo mv -f /tmp/init.pp $PUPPET_MODULES/docker_install/manifests/init.pp
  sudo mv -f /tmp/env $PUPPET_MODULES/docker_install/files
  sudo mv -f /tmp/init_jenkins.pp $PUPPET_MODULES/jenkins/manifests/init.pp
  sudo cp /usr/share/doc/puppet/examples/etckeeper-integration/*commit* $PUPPET_DIR
  sudo chmod 755 $PUPPET_DIR/etckeeper-commit-p*
fi


sudo ufw allow 8140/tcp

# al detener e iniciar el servicio se regeneran los certificados
echo "Reiniciando servicios puppetmaster y puppet agent"
sudo systemctl stop puppetmaster && sudo systemctl start puppetmaster
sudo systemctl stop puppet && sudo systemctl start puppet


# limpieza de configuración del dominio utn-devops.localhost es nuestro nodo agente.
# en nuestro caso es la misma máquina
sudo puppet node clean utn-devops-vagrant-grupo2-u3-ubuntu.localhost

# Habilito el agente
sudo puppet agent --certname utn-devops-vagrant-grupo2-u3-ubuntu.localhost --enable

# Genera certificados en nodo agente (Solo ejecutar en master)
sudo puppet cert sign utn-devops-vagrant-grupo2-u3-ubuntu.localhost

# Instala el servidor Jenkins con el software adicional que necesite para ejecutar el ciclo de Integración Continua. Todo lo instalado se
# realizará mediante Puppet

echo "-----------------------------> VERIFICANDO $PUPPET_MODULES"
if [ -d "$PUPPET_MODULES" ]; then
    echo "--------------utn-devops-vutn-devops-vagrant-grupo2-u1-ubuntuagrant-grupo2-u1-ubuntu---------------> VERIFICANDO docker-compose.yml"
    if [ -f "$PUPPET_MODULES/jenkins/manifests/init.pp" ]; then
        echo "Archivo init.pp encontrado!"
        sudo puppet agent -t --debug                
    else
        echo "WARNING: El archivo init.ppl no existe."
    fi
else
    echo "WARNING: No existe el directorio $PUPPET_MODULES"
fi


R='\033[0;31m'   #'0;31' is Red's ANSI color code
G='\033[0;32m'   #'0;32' is Green's ANSI color code
Y='\033[0;33m'   #'1;32' is Yellow's ANSI color code
B='\033[0;34m'   #'0;34' is Blue's ANSI color code
NOCOLOR='\033[0m'

PWD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo -e "${Y}----------------------------->$ INSTALACION  FINALIZADA\n\n"
echo -e "${Y}-----------------------------> Acceso a Jenkins: http://127.0.0.1:8082\n"
echo -e "${Y}-----------------------------> Password: " $PWD
