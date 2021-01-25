# netdavis IOT

This repo contains Ansible Plays that bootstrap the official Raspberry Pi OS image with the
software required to host IOT devices on the netdavis.io network. These Plays are intended to
be run within a [Packer](https://www.packer.io/) VM, but may also be run on a remote Raspberry
Pi.

## Setup

Conveniently, the [`devenv.yml`](./devenv.yml) Playbook is provided to automate the setup of
this projects development environment, on an Ubuntu 20.04+ machine. It must be run from within
a Python virtual environment.

> **Note:** If you are not running Ubuntu 20.04+, then you will need to adapt the steps
> provided here (and in the Playbook) for your system.

If this is your first time setting up the development environment for this project, then follow
the instructions in [ubuntu-dev-environment.md](./docs/ubuntu-dev-environment.md),
instead.

### pyevn

It's recommended to use pyenv to manage your Python version for this project.

Instruct pyenv to switch to the version of Python tracked in the
[`.python-version`](./.python-version) file that lives in the root of this project:

```bash
$ eval "$(pyenv init -)"
```

> **Note:** this can be run from any folder in this project. **Additionally:** this command
> will need to be run everytime you open a new terminal to work on this project.

### Poetry

Install Ansible and its dependencies with [Poetry](https://python-poetry.org/):

```bash
$ poetry install
```

## Running the Ansible Plays

Ansible connects to managed nodes via SSH. Load your SSH private key into `ssh-agent` by
running the following command:

```bash
$ ssh-add ~/.ssh/id_rsa
```

### Set the Ansible Vault password

The `vault.password.py` file is uses the `ANSIBLE_VAULT_PASSWORD` environment variable to
decrypt Ansible Vault files in this project. It's recommended to create an `ansible.vault` file
in the root of this project, with the following contents:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='secret_vault_password_shhh'
```

Then source the file in the terminal you are using to work on this project, like so:

```bash
$ source vault.password
```

If you don't set the `ANSIBLE_VAULT_PASSWORD` environment variable then Ansible will print an
**`ERROR! Decryption failed`** message to the console.

> **Note:** you will have to source this file each time you open a new terminal.

### Test the connection via an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
$ poetry run ansible localhost -m ping
```

> **Note:** see [`ansible.cfg`](./ansible.cfg) for other nodes.

### Run the devenv Playbook

This Playbook will provision your Host machine with Packer and the `packer-builder-arm` plugin
required to bootstrap a Raspberry Pi OS (`armv7l`) image. Run the following command to execute
the Playbook:

```bash
$ poetry run ./ansible-playbook-wrapper devenv.yml --limit=localhost
```

## Bootstrap the Image with Packer

Packer is used to bootstrap the official Raspberry Pi OS image with the software and
configuration required to host this project. All of the tool versions are hardcoded in
[`group_vars/all/main.yml`](./group_vars/all/main.yml) to prevent version incompatibility
issues and other breakage.

### Example command

This repo provides the [`packer-wrapper`](./packer-wrapper) script for executing Packer builds.
This script makes life easier for the developer in a few ways. It:

- Turns on the Packer logger
- Validates the Packer build template
- Passes the Ansible Vault password to the `root` environment in which Packer runs

The Packer build expects that the Ansible Vault Password is set as the `ANSIBLE_VAULT_PASSWORD`
environment variable. If you changed terminals or you are starting fresh, then make sure you
follow the steps above for setting it.

Then kickoff the Packer build by running the wrapper script:

```bash
$ ./packer-wrapper -var "tag=$(git rev-parse --short HEAD)" build_charity.pkr.hcl
```

This Packer build will spit out a `charity-<tag>.img` file in to the project root.

## Flashing the Image

Plug a MicroSD card (or some other form of secondary memory) into your host machine. You can
locate the block device using `lsblk`. Then run the following command to flash the newly
modified image to your MicroSD card:

```bash
$ pv charity-<tag>.img | sudo dd bs=19M iflag=fullblock conv=fsync of=/dev/sdb
```

> **Attention!** Adjust the `bs` operand to the max write speed of your MicroSD card, USB 3.0
> device, etc.
