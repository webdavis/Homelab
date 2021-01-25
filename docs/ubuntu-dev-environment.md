# Ubuntu Dev Environment Installation and Setup

To get started on this project, a few tools must be installed on your development machine.
This document assumes you are using an Ubuntu 20.04+ machine; though, it should be easy
enough to adapt the installation instructions for a different OS.

Conveniently, the [`devenv.yml`](../devenv.yml) Playbook is provided to automate the setup of
this projects development environment on an Ubuntu 20.04+ machine. However, it must be run from
within a Python virtual environment.

> **Note:** If you are not running Ubuntu 20.04+, then you will need to adapt the steps
> provided here (and in the Playbook) for your system.

## pyenv

It's recommended to use [pyenv](https://github.com/pyenv/pyenv) to manage Python versions.

However, some build dependencies are required for pyenv to install versions of Python. On
Ubuntu 20.04+ systems, they can be installed as follows:

```bash
$ sudo apt update
$ sudo apt install --no-install-recommends make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

Install `git`:

```bash
$ sudo apt install git
```

Now clone the pyenv project using `git`:

```bash
$ git clone https://github.com/pyenv/pyenv.git ~/.pyenv
```

Run the following commands to add `pyenv` to your shell environments `$PATH`:

```bash
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
```

Then source your `~/.bashrc`, like so:

```bash
$ source ~/.bashrc
```

Install the version of Python tracked in [`.python-version`](../.python-version):

```bash
$ cat .python-version | pyenv install
```

Now switch to that version, like so:

```bash
$ eval "$(pyenv init -)"
```

## Poetry

This project has some dependencies that are installed via [Poetry](https://python-poetry.org/).
The Poetry project provides a custom installer for Linux; it can be run as follows:

```bash
$ curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
```

To make the `poetry` executable availabe on your current shells `$PATH`, run:

```bash
$ source ~/.poetry/env
```

Poetry uses the [`pyproject.toml`](../pyproject.toml) and [`poetry.lock`](../poetry.lock)
files to track dependencies. Install the project dependencies, like so:

```bash
$ poetry install
```

### Two ways to use the Poetry environment

You can either spawn a new shell with the Python virtual environment instantiated, like so:

```bash
$ poetry shell
```

Or you can run commands ad-hoc style by prepending them with `poetry run`, like so:

```bash
# Example command
$ poetry run ansible localhost -m shell -a "free -h"
```

## Running the Ansible Plays

Ansible connects to managed nodes via SSH. Load your SSH private key into `ssh-agent` by
running the following command:

```bash
$ ssh-add ~/.ssh/id_rsa
```

### Set the Ansible Vault password

The `vault.password.py` file uses the `ANSIBLE_VAULT_PASSWORD` environment variable to decrypt
Ansible Vault files in this project. It's recommended to create an `ansible.vault` file in the
root of this project, with the following contents:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='secret_vault_password_shhh'
```

Then source the file in the terminal you are using to work on this project, like so:

```bash
$ source vault.password
```

If you don't set the `ANSIBLE_VAULT_PASSWORD` environment variable then Ansible will print a
**`ERROR! Decryption failed`** message to the console.

> **Note:** you will have to source this file each time you open a new terminal.

### Create your own Ansible Vault file for this project

Copy and paste the following file contents into the `group_vars/all/vault.yml`:

```yaml
---
#
# This file contains secret variables... shhhh.
#

vault_account:
  charity:
    localadmin:
      password: <create a strong user account password and put it here>
      ssh_key:
        public: <put your SSH Public Key here>
        private: |
          <put your SSH Public Key here>

devices:
  charity:
    mac_address: <put the MAC Address of your Raspberry Pi here>
    capacity: "<the capacity of your Raspberry Pi (e.g. 2GB, 4GB, etc)>"
```

Then use Ansible Vault to encrypt the file, like so:

```bash
$ poetry run ansible-vault encrypt group_vars/all/vault.yml
```

### Test the connection via an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
$ poetry run ansible localhost -m ping
```

> **Note:** see [`ansible.cfg`](../ansible.cfg) for other nodes.

### Run the devenv Playbook

This Playbook will provision your Host machine with Packer and the `packer-builder-arm` plugin
required to bootstrap a Raspberry Pi OS (`armv7l`) image.

It's required that the user account that runs this playbook has `sudo` access. If your user
account must enter a password to acquire `sudo` access then, from the root of this project, run
the following `ansible-playbook` command with the `--ask-become-pass` command flag, like so:

```bash
$ poetry run ./ansible-playbook-wrapper devenv.yml --ask-become-pass --limit=localhost
```

If your user can run `sudo` without providing a password, then run the following command:

```bash
$ poetry run ./ansible-playbook-wrapper devenv.yml --limit=localhost
```

## Bootstrap a Raspberry Pi Image with Packer

Packer is used to bootstrap the official Raspberry Pi OS image with the software and
configuration required to host this project. All of the tool versions are hardcoded in
[`group_vars/all/main.yml`](../group_vars/all/main.yml) to prevent version incompatibility
issues and other breakage.

### Example command

This repo provides the [`packer-wrapper`](../packer-wrapper) script for executing Packer builds.
This script makes life easier for the developer in a few ways. It:

- Turns on the Packer logger
- Validates the Packer build template
- Passes the Ansible Vault password to the `root` environment in which Packer runs

The Packer build expects that the Ansible Vault Password is set as the `ANSIBLE_VAULT_PASSWORD`
environment variable. If you changed terminals or you are starting fresh, then make sure you
follow the steps mentioned earlier for setting it.

Then kickoff the Packer build by running the wrapper script from the root of this project, like
so:

```bash
$ ./packer-wrapper -var "tag=$(git rev-parse --short HEAD)" build_charity.pkr.hcl
```

This Packer build will spit out a `charity-<tag>.img` file in to the project root.

> **Note:** charity is the nickname I have given the Raspberry Pi that hosts the services in
> this project.

## Flashing the Image

Plug a MicroSD card (or some other form of secondary memory) into your host machine. You can
locate the block device using `lsblk`. Then, from the root of this project, run the following
command to flash the newly modified image to your MicroSD card:

```bash
$ pv charity-<tag>.img | sudo dd bs=19M iflag=fullblock conv=fsync of=/dev/sdb
```

> **Attention!** Adjust the `bs` operand to the max write speed of your MicroSD card, USB 3.0
> device, etc.
