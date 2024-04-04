#!/bin/bash
echo "#########################################################################"
echo "########################## INICIANDO SCRIPT #############################"
echo "#########################################################################"
echo "-------------------------------------------------------------------------"

#Aprovisionamiento de software

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
######## Instalacion de DOCKER ########
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




