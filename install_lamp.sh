#!/bin/bash
set -x

#Variables de configuración
#################################################

MYSQL_ROOT_PASSWORD=root
PHPMYADMIN_APP_PASS=root
STATS_USER=usuario
STATS_PASSWORD=usuario

EMAIL_HTTPS=zakariyasmr1920@gmail.com
DOMAIN=iaw-zakariya.ddns.net

#################################################

#Actualizamos el sistema
apt update
apt upgrade -y

#Instalamos el servidor web Apache
apt install apache2 -y

#Instalamos MySQL Server
apt install mysql-server -y

#Cambiamos la contraseña ddel usuario root
mysql <<< "ALTER USER root@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASSWORD';"

# Instalamos los paquetes de PHP
apt install php libapache2-mod-php php-mysql -y

# Reiniciamos el servidor web Apache
systemctl restart apache2 

# Copiamos el archivo info.php en el directorio de Apache
cp info.php /var/www/html

#########################################
# Instalación de herramientas adicionales
#########################################

# Instalamos Adminer
cd /var/www/html
mkdir adminer
cd adminer
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php
mv adminer-4.8.1-mysql.php index.php

# Actualizamos el propietario y el grupo del directorio /var/www/html
chown www-data:www-data /var/www/html -R

# Herramienta: phpMyAdmin
# 
# Instalamos las dependencias
apt install php-mbstring php-zip php-gd php-json php-curl -y

# Configuramos las respuestas para hacer una instalación desatendida de phpMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASS" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASS" | debconf-set-selections

# Instalamos phpMyAdmin

apt install phpmyadmin -y

# Instalamos GoAccess

echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list
wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key add -
apt update
apt install goaccess -y

# Ejecutamos goaccess en un terminal virtual
mkdir /var/www/html/stats
chown www-data:www-data /var/www/html/stats -R
screen -dmL goaccess /var/log/apache2/access.log -o /var/www/html/report.html --log-format=COMBINED --real-time-html

# Realizamos los pasos para proteger un directorio del servidor web con contraseña
htpasswd -cb /home/ubuntu/.htpasswd $STATS_USER $STATS_PASSWORD

#Copiamos el archivo de configuración  de Apache
cd ~/IAW-ZAKARIYA
cp 000-default.conf /etc/apache2/sites-available

# Reiniciamos el servidor
systemctl restart apache2


#-----------------------------------------------------------------------------------------
#Despliegue de la aplicacón web
#-----------------------------------------------------------------------------------------
cd /var/www/html

#Clona,os el repositorio de la aplicación
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git

#Movemos el código fendte de la aplicación al directorio /var/html
mv iaw-practica-lamp/src/* /var/www/html

#Importamos el script de base de datos
mysql -u root -p$MYSQL_ROOT_PASSWORD < iaw-practica-lamp/db/database.sql

#Eliminamos el archivo index.html
rm /var/www/html/index.html

#Eliminamos el directorio del repositorio
rm -rf /var/www/html/iaw-practica-lamp

#Cambiamos el propietario y el grupo de los archivos
chown www-data:www-data /var/www/html -R

#----------------------------------
# Configuramos HTTPS
#----------------------------------


# Realizamos la instalacion de snapd
snap install core
snap refresh core

# Eliminamos instalaciones previas de certbot con apt
apt-get remove certbot

# Intalamos certbot con snap
snap install --classic certbot

# Solicitamos el certificado HTTPS
sudo certbot --apache -m $EMAIL_HTTPS --agree-tos --no-eff-email -d $DOMAIN