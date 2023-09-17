#!/usr/bin/env bash

function dra {
  docker rm "$(docker ps -aq)"
}

function dsa {
  docker stop "$(docker ps -aq)"
}

function dpa {
  echo stop containers
  dsa
  echo remove containers
  dra
  echo prune networks..
  docker network prune -f
  echo prune volumes..
  docker volume prune -f
}
