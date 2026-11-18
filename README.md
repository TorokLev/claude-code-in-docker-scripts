# Claude-code-in-docker

Claude-code is not guaranteed that it accesses only the directories on your machine that you specify it work with.

With these scripts you can restrict claude-code to operate exclusively in its directory only. Rootless docker service is used to ensure guaranties.

# Usage

1. claude-code-in-docker-setup.sh

This builds a docker image with claude-code

2. claude-code-in-docker-start.sh

This starts the image in a container.
Peristent OAUTH2 authentication is configured.
It behaves as a deamon: you have to start and stop it.

3. claude-code-in-docker-login.sh

In order to use the container you have to login into the container.
Use Ctrl+C to quit, and start this script to relogin.
As long as a deamon is running in the container you can login.

4. claude-code-in-docker-bash.sh

With this tool you may check the operation of the container.


