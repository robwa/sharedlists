# Sharedlists

[![Dependency Status](https://gemnasium.com/badges/github.com/foodcoops/sharedlists.svg)](https://gemnasium.com/github.com/foodcoops/sharedlists)
[![Docker Status](https://img.shields.io/docker/build/foodcoops/sharedlists.svg)](https://hub.docker.com/r/foodcoops/sharedlists)

Sharedlists is a simple rails driven database for managing multiple product lists of various suppliers.

This app is used in conjunction with [foodsoft](https://github.com/foodcoops/foodsoft).

## Setup

Copy `config/database.yml.SAMPLE` to `config/database.yml` and

    docker-compose run app bundle
    docker-compose run app rake db:setup

## Development

    docker-compose up

## Creating a user

To access sharedlists, you'll need to create a user (and I guess you want admin access).

    docker-compose run --rm app rails c
    > u = User.new(email: 'admin@example.com', password: 'secret')
    > u.admin = true
    > u.save!
    > exit

## Production

Either fetch the image, or build it:

    docker pull sharedlists:latest
    # or
    docker build --tag sharedlists:latest --rm .

Then set environment variables `SECRET_TOKEN` and `DATABASE_URL` and run:

    docker run --name sharedlists_web \
      -e SECRET_TOKEN -e DATABASE_URL -e RAILS_FORCE_SSL=false \
      sharedlists:latest

To run cronjobs, start another instance:

    docker run --name sharedlists_cron \
      -e SECRET_TOKEN -e DATABASE_URL \
      sharedsts:latest  ./proc-start cron

