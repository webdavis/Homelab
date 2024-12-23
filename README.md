<p align="center">
    <img src="./gallery/homelab-icon-1.png" alt="Homelab Icon" width="300" height="300">
</p>

# Homelab

This repo contains automation that bootstraps Raspberry Pis with services bound for my home
network. The automation in this project includes the following:

- [Ansible](https://www.ansible.com/) plays that manage the configuration of services on the device.
- [Docker](https://docs.docker.com/get-started/) containers that host and run services.
- Wrapper scripts that ease the usage of the Ansible commands.

## Getting Started

If this is your first time setting up the development environment for this project, please
refer to the instructions in [ubuntu-dev-environment.md](./docs/ubuntu-dev-environment.md)
first.

The following instructions will assume that you've already done this.

### pyevn

This project uses [pyenv](https://github.com/pyenv/pyenv) to manage and track its Python
version.

Run the following command to instruct pyenv to switch to the Python version specified in the
[`.python-version`](./.python-version) file located at the root of this project: Run the
following command to instruct

```bash
eval "$(pyenv init -)"
```

> \[!TIP\]
> This can be run from any folder in this project. **Additionally,** this command will need to
> be run *every time* you open a new terminal to work on this project.

### PDM

Install Ansible and its dependencies with [PDM](https://github.com/pdm-project/pdm):

```bash
./pw pdm sync
```

## Running the Ansible Plays

Ansible uses SSH to connect to managed nodes. To avoid repeatedly entering the private key
passphrase, load your SSH private key into ssh-agent with the following command:

```bash
ssh-add ~/.ssh/id_rsa
```

### Test the connection using an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
./pw pdm run --venv in-project ansible localhost -m ping
```

> \[!TIP\]
> See [`hosts.ini`](./hosts.ini) for other managed nodes.

## Ansible Role: Security

In order to run this role your playbook must make use of the following:

- Elevated privileges using `become: yes`
- Collect system information using `gather_facts: yes`

To run this role, your playbook must include the following:

- **Elevated privileges:** Use `become: yes` to execute tasks requiring administrative access.
- **System information collection:** Enable `gather_facts: yes` to collect essential system
  details before executing tasks.

For example:

```yaml
- hosts: servers
  name: Configure security settings
  become: yes
  gather_facts: yes
  tasks:
    - import_role: name=security
```
