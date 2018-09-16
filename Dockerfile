FROM ubuntu:16.04

MAINTAINER Turbot HQ, Inc <support@turbot.com>

# Get ansible package version from the builder and save to environment
ARG ANSIBLE_VERSION
ENV ANSIBLE_VERSION $ANSIBLE_VERSION

# Install specific Ansible version using pip.
# Dependencies, such as the openssh-client (via sshpass) must also be installed
# since pip will not find or install them by default. The dependency list was
# derived from exploring "apt-cache showpkg ansible".
# Ansible requires a home directory for the turbotd user, or we have to set
# 20+ individual environment settings to a different location. See https://github.com/ansible/ansible/blob/devel/lib/ansible/constants.py
RUN groupadd --system --gid 973 turbotd && \
    useradd  --system --gid 973 --uid 973 --create-home turbotd && \
    apt-get -qq update && \
    apt-get install -qqy sshpass python-pip libssl-dev libffi-dev git netcat-openbsd jq traceroute iputils-ping dnsutils && \
    pip install ansible==2.5 && \
    pip install ansible[azure] && \
    pip install azure-cli && \
    pip install "pywinrm>=0.2.2" && \
    pip install pywinrm[credssp] && \
    pip install 'azure>=2.0.0' --upgrade && \
    pip install --upgrade pip && \
    ansible --version

# Turbot builds settings and variables in dictionaries, use merge so they
# can be combined together. See http://docs.ansible.com/intro_configuration.html#hash-behaviour
ENV ANSIBLE_HASH_BEHAVIOUR=merge

# Since ansible in running unattended and our list of hosts constantly
# changes we disable host key checking. See http://docs.ansible.com/intro_getting_started.html#host-key-checking
ENV ANSIBLE_HOST_KEY_CHECKING=False

# Use SCP instead of SFTP since it's more commonly supported on different
# instances and should have a negligible impact on performance. First required
# example was CfnCluster AMIs running Amazon Linux 2016.
ENV ANSIBLE_SCP_IF_SSH=y

# Establish the ansible directory and set permissions. Note that this only sets
# perms for the current files, not for those mounted as volumes later.
COPY ansible /opt/turbot/ansible
RUN chown -R turbotd:turbotd /opt/turbot/ansible
COPY main.yml /opt/turbot/process/templates/rendered/playbook/main.yml

# Default to the playbook location for running
WORKDIR /opt/turbot/process/templates/rendered/playbook
RUN chown -R turbotd:turbotd /opt/turbot/process/templates/rendered/playbook
# Run the process and playbook as non-root. This works only since the volumes
# have been chowned to turbotd UID by the host before running.
USER turbotd

# Custom script for running the ansible job
ENTRYPOINT [ "/opt/turbot/ansible/run-ansible" ]

#CMD [ "--verbose", "--inventory-file=/opt/turbot/process/templates/rendered/hosts", "--private-key=/opt/turbot/process/templates/rendered/keys/$turbot.pem", "main.yml" ]
