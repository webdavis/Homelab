# netdavis IOT

This repo contains automation that bootstraps Raspberry Pis with services bound for my home
network, dubbed `netdavis.net`. The automation in this project includes the following:

- [Ansible](https://www.ansible.com/) plays that manage the setup of services on the device.
- Wrapper scripts that ease the usage of the Ansible commands.

## Setup

If this is your first time setting up the development environment for this project, please
refer to the instructions in [ubuntu-dev-environment.md](./docs/ubuntu-dev-environment.md)
first.

The following instructions will assume that you've already done this.

### pyevn

This project uses [pyenv](https://github.com/pyenv/pyenv) to manage its Python version.

Run the following command to instruct pyenv to switch to the version of Python tracked in the
[`.python-version`](./.python-version) file, which is located in the root of this project:

```bash
eval "$(pyenv init -)"
```

> [!TIP]
> This can be run from any folder in this project. **Additionally,** this command will need to
> be run every time you open a new terminal to work on this project.

### PDM

Install Ansible and its dependencies with [PDM](https://github.com/pdm-project/pdm):

```bash
pdm sync
```

## Running the Ansible Plays

Ansible connects to managed nodes via SSH. Load your SSH private key into `ssh-agent` by
running the following command:

```bash
ssh-add ~/.ssh/id_rsa
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
source vault.password
```

If you don't set the `ANSIBLE_VAULT_PASSWORD` environment variable then Ansible will print the
following message to console: **`ERROR! Decryption failed`**.

> [!TIP]
> You will have to source this file each time you open a new terminal.

### Test the connection via an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
pdm run --venv in-project ansible localhost -m ping
```

> [!TIP]
> See [`hosts.ini`](./hosts.ini) for other managed nodes.
