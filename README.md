![Docker Pulls](https://img.shields.io/docker/pulls/2fauth/2fauth?style=flat-square&logo=docker) ![https://github.com/Bubka/2FAuth-Docker/blob/php/7.4-apache/LICENSE](https://img.shields.io/github/license/Bubka/2FAuth.svg?style=flat-square) [![Use PHP7.4](https://img.shields.io/badge/php-7.4.*-8892BF.svg?style=flat-square)](https://secure.php.net/downloads.php) 

# Docker setup for 2FAuth

Deploy [2FAuth](https://github.com/Bubka/2FAuth) using a docker container in a breeze.

> 2FAuth : A Web app to manage your Two-Factor Authentication (2FA) accounts and generate their security codes

## Purpose
This repository contains the necessary files to build the [2fauth/2fauth](https://hub.docker.com/repository/docker/2fauth/2fauth) dockerhub image and run 2FAuth in a docker container via docker-compose.

This docker-compose setup does not provide a full development environment, it is for production only.

## How to use it
### Dockerfile
You can use it to build your own 2FAuth image if the one on dockerhub does not fit your needs.
The image is based on the [official php7.4-apache](https://hub.docker.com/_/php) docker image, so it runs an apache2 web server on a debian buster slim distro.

There is no database management system in the image.

Simply runs `docker build -t YourImageName .` to build it.

### docker-compose.yml
This is the best option if you just want to run 2FAuth and use it.
It will run the 2FAuth image binded to a MySQL image with persisted volumes.

- Clone this repo
- Download this [.env.example](https://github.com/Bubka/2FAuth/blob/master/.env.example) file in the same folder and rename it `.env`
- Edit the `.env` file and adapt the settings to your needs (see instructions in the file)
- Open a terminal on the repo directory and run `docker-compose up -d && docker-compose logs -f`
- Open your browser on http://localhost/
- Enjoy :)