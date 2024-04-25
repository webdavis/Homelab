# This Dockerfile configures an Ubuntu 22.04 LTS environment with systemd.
#
# Run the following command to create the image:
#
#   $ docker build --force-rm --tag webdavis/ubuntu:22.04-systemd .
#
# Then run the container, like so:
#
#   $ sudo docker run -d -t \
#           --tmpfs /run \
#           --tmpfs /run/lock \
#           --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw \
#           --hostname ubuntu \
#           --name ubuntu_22.04_systemd \
#           webdavis/ubuntu:22.04-systemd
#
# Finally, run the following command to enter container:
#
#   $ docker exec -ti ubuntu_22.04_systemd /bin/bash -l
#
FROM ubuntu:22.04
LABEL maintainer "Stephen A. Davis <stephen@webdavis.io>"
ENV container docker

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends systemd systemd-sysv \
    && apt-get autoremove -y; apt-get clean \
    && find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \; \
    && systemctl set-default multi-user.target
STOPSIGNAL SIGRTMIN+3

# Reserve this folder for the host volume.
VOLUME ["/sys/fs/cgroup"]

CMD ["/sbin/init"]
