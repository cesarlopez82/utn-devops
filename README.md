# utn-devops
utn-devops 2024

# Para hacer el deploy de la vm clonar el repo y ejecutar el siguiente comando
vagrant up --provision

# Se creará la vm -> utn-devops-vagrant-grupo2-u1-ubuntu
La aplicacion puede consumirse en localhost:8080

# el script Vagrant-bootstrap.sh realizará las siguientes tareas
#   Desinstala python3-pip en la VM 
#   Crea el directorio /var/db/mysql donde se persistiran los datos de la DB MYSQL de la app
#   Carga el archivo de configuracion del firewall /etc/default/ufw
#   Crea una partición swap. Previene errores de falta de memoria
#   CLONAR/ACTUALIZAR la app https://github.com/cesarlopez82/utn-devops-app.git
#   Verifica si docker esta instalado y lo instala si no está.
#   Levanta 3 contenedores mediante docker-compose up -d --build
#   -python_api     (es la api)
#   -mysql_db       (es la db)
#   -unit_tests_python_api  (ejecuta unit_tests de la api)
#   se puede ver el resultado de los unit tests ingresando a la vm con "vagrant ssh" y luego ejecutando el comando "docker logs unit_tests_python_api"
 


# La aplicacion levanta una API en Python con los siguientes endpoint de test
localhost:8080
localhost:8080/welcome
