# Automatic Docker builds for Purpur Minecraft

This repository checks automatically every hour for new purpur server builds, builds new images with them and uploads them to the docker registry.

## Links
- Images: [hub.docker.com/r/josxha/minecraft-purpur](https://hub.docker.com/r/josxha/minecraft-purpur)
- Repository: [github.com/josxha/minecraft-purpur-docker](https://github.com/josxha/minecraft-purpur-docker)
- Purpur: [https://purpurmc.org/downloads](https://purpurmc.org/downloads)

## Why to use this image
- [x] Easy to use and configure
- [x] Up to date with the latest purpur builds
- [x] Much smaller image size compared to other purpur images
- [x] Open source repository

## Get Started
1. Install docker ([docker docs](https://docs.docker.com/get-docker/))
2. Install docker-compose ([docker docs](https://docs.docker.com/compose/install/))
3. Example content of your `docker-compose.yml` file:
```yaml
version: '3'
services:
    minecraft:
        image: josxha/minecraft-purpur:latest # or e.g. 1.18.1
        container_name: minecraft
        restart: unless-stopped
        ports:
            - 0.0.0.0:25565:25565
        volumes:
            - ./data:/data:rw
        # user: 25565:25565
        environment:
            - TZ=Europe/London
            - RAM=4G
```
4. (optional) If you want to run the container not as root
   1. uncomment the line `user: 25565:25565`
   2. create the data directory with `mkdir ./data`
   3. change the directory permissions with `sudo chown 25565:25565 ./data`
5. Run `docker-compose up -d` in the directory of your `docker-compose.yml` file.
6. (optional) Use [watchtower](https://hub.docker.com/r/containrrr/watchtower) to keep your container up to date with the latest image build automatically.

## Image Tags
- **latest**: Newest minecraft version with the latest purpur build
- **1.18-latest**, **1.17-latest**, **etc.** for the latest purpur build of this major minecraft version
- **1.18.1**, **1.18**, **1.17.1**, **etc.** for the latest purpur build of this minecraft version
- **<minecraft_version>-<purpur_build>** to use specific purpur build

See all the available tag [here](https://hub.docker.com/r/josxha/minecraft-purpur/tags).