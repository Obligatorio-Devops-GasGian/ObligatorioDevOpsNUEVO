# Example Voting App

A simple distributed application running across multiple Docker containers.

## Como usar
Configurar secretos de github con las credenciales de AWS.

Para generar el action de ci/cd es necesario hacer un push o pull request a una de las siguientes ramas: infra, infra-config.
Esto disparara un workflow de implementacion de infraestructura, configuracion de AWS y creación de logs en AWS.
Al finalizar exitosamente este workflow se ejecuta el deployment de la app, primero pasa por una serie de tests y una quality gate, si cumple los requisitos procede a configurar AWS, subir las imagenes de contenedores a ECR, fuerza la actualizacion del servicio de ECS deployeado en el anterior workflow.

## Documentación adicional con diagramas aquí:
https://docs.google.com/document/d/1_TucyKCOOgaXXq9sJoOTv_kqFsDlyX3ayPlrXV1f8C4/edit?tab=t.0