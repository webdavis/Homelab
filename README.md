# netdavis IOT

This repo contains automation that bootstraps a Raspberry Pi 4B (2GB) with services bound for
my home network, which I dub as netdavis.io. The automation in this project includes the
following:

- A [Packer](https://www.packer.io/) template that modifies the official Raspberry Pi (32-bit) OS.
- [Ansible](https://www.ansible.com/) Plays that manage the setup of services on the device.
- Wrapper scripts that easy the usage of the `packer` and `ansible-playbook` commands.

## Setup

If this is your first time setting up the development environment for this project, then follow
the instructions in [ubuntu-dev-environment.md](./docs/ubuntu-dev-environment.md), instead. The
following instructions will assume that you've already done this and that you are returning to
work on this project after already having worked on it before.

### pyevn

It's recommended to use pyenv to manage your Python version for this project.

Run the following command to instruct pyenv to switch to the version of Python tracked in the
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

### Test the connection via an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
$ poetry run ansible localhost -m ping
```

> **Note:** see [`ansible.cfg`](./ansible.cfg) for other nodes.

## Bootstrap a Raspberry Pi Image with Packer

Packer is used to bootstrap the official Raspberry Pi OS image with the software and
configuration required to host this project.

### Example command

The Packer build expects that the Ansible Vault Password is set as the `ANSIBLE_VAULT_PASSWORD`
environment variable. If you changed terminals or you are starting fresh, then make sure you
follow the steps mentioned earlier for setting it.

Then kickoff the Packer build by running the wrapper script, like so:

```bash
$ ./packer-wrapper -var "tag=$(git rev-parse --short HEAD)" build_charity.pkr.hcl
```

This Packer build will spit out a `charity-<tag>.img` file in to the project root.

> **Note:** charity is the nickname I have given the Raspberry Pi that hosts the services in
> this project.

## Flashing the Image

Plug a MicroSD card (or some other form of secondary memory) into your host machine. You can
locate the block device using `lsblk`. Then run the following command to flash the newly
modified image to your MicroSD card:

```bash
$ pv charity-<tag>.img | sudo dd bs=19M iflag=fullblock conv=fsync of=/dev/sdb
```

> **Attention!** Adjust the `bs` operand to the max write speed of your MicroSD card, USB 3.0
> device, etc.
