FROM ubuntu:16.04
MAINTAINER Kamil Trzciński <kamil@gitlab.com>

# Install required packages
RUN apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
      ca-certificates \
      openssh-server \
      wget \
      apt-transport-https \
      vim \
      nano \
      patch \
      net-tools \
      git-annex && rm -rf /var/lib/apt/lists/*
#RUN ls -lhas /opt/gitlab/etc/; sed -i -r -e "s~^# redis\['enable'\]y.+~maxmemory 1gb~g"  /opt/gitlab/etc/gitlab.rb.template
# Remove MOTD
RUN rm -rf /etc/update-motd.d /etc/motd /etc/motd.dynamic
RUN ln -fs /dev/null /run/motd.dynamic

# Copy assets
COPY RELEASE /
COPY assets/ /assets/
RUN chmod 700 /assets/setup; chmod 700 /assets/wrapper; /assets/setup;

# Allow to access embedded tools
ENV PATH /opt/gitlab/embedded/bin:/opt/gitlab/bin:/assets:$PATH

# Resolve error: TERM environment variable not set.
ENV TERM xterm

# Expose web & ssh
EXPOSE 443 80 22 2289

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle signal, trigger runit and reconfigure GitLab
CMD ["/assets/wrapper"]
