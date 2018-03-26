**DOCKER LAMP**

Servidor Apache2, PHP7.1, XDebug enabled, MySQL 5.5 y PHPMyAdmin.

Desarrollar dentro de la carpeta `/src`

El Default root password de MySQL es: `docker`

Utilizar de la siguiente manera:

1. Buildear imagen

    docker build -f Dockerfile . -t nombre-imagen:latest

2. Iniciar Container

    docker run --name nombre-container -p 3000:80 -d -v ${PWD}:/var/www/html nombre-imagen:latest