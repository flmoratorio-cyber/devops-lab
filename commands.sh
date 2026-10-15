#!/usr/bin/env bash
# Ticket 04 - Docker core operations (run on a worker, e.g. wk1).
# Walkthrough, not meant to be executed top to bottom without reading.

docker pull nginx                                   # official image
docker image ls

# 1) detached container + port mapping (flags BEFORE the image name)
docker run -d --name web -p 8080:80 nginx:latest
curl -s localhost:8080 | head -n 5

# 2) bind mount a single file over the default page
docker rm -f web
docker run -d --name web -p 8080:80 \
  -v "$PWD/index.html":/usr/share/nginx/html/index.html:ro \
  nginx:latest

# 3) intentional failure + diagnosis
docker rm -f web
docker run -d --name web -p 8080:80 \
  -v "$PWD/does-not-exist.html":/usr/share/nginx/html/index.html:ro \
  nginx:latest || true
docker ps -a                                        # state: Created / Exited(<code>)
docker logs web                                     # read the actual error

# cleanup
docker rm -f web 2>/dev/null || true
