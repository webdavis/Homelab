<p align="center">
    <img src="./gallery/homelab-icon-1.png" alt="Homelab Icon" width="300" height="300">
</p>

# Homelab

This repository automates the setup of Raspberry Pis with services for my home network. It
makes use of the following tools:

- **[Ansible](https://www.ansible.com/):** Playbooks to configure services on each device.
- **[Docker](https://docs.docker.com/get-started/):** Containers that run and manage the services.
- **Wrapper scripts:** Simplify working with Ansible and other tools in this project.

## Getting Started

If this is your first time setting up the development environment, follow the instructions in
[ubuntu-dev-environment.md](./docs/ubuntu-dev-environment.md) first.

The instructions below assume that setup is complete.

### pyevn

This project uses [pyenv](https://github.com/pyenv/pyenv) to manage and track its Python
version.

Run the following command to switch to the Python version specified in the
[`.python-version`](./.python-version):

```bash
eval "$(pyenv init -)"
```

> \[!WARNING\]
> You can run this command from anywhere inside the project.  
> However, you will need to run it **every time you start a new terminal session** before
> working on the project.

### Pyprojectx and PDM

This project uses [Pyprojectx](https://github.com/pyprojectx/pyprojectx) and
[PDM](https://github.com/pdm-project/pdm) to manage Python dependencies in a consistent,
isolated environment:

- **Pyprojectx:** Provides the [`./pw`](./pw) wrapper script, ensuring all project tools run
  consistently without needing global installations (including PDM).
- **PDM:** manages the Python dependencies used by this project (including Ansible).  

To install the dependencies, run:

```bash
./pw pdm sync
```

> **Tip:** run `./pw which pdm` to see the full path of the `pdm` used by this project. It
> should look something like:
> `<path_to_this_project>/Homelab/.pyprojectx/venvs/main-ab061d9d4f9bea1cc2de64816d469baf-py3.13/bin/pdm`

## Running the Ansible Plays

Ansible uses SSH to connect to managed nodes.

To avoid repeatedly entering the private key passphrase, load your SSH private key into
ssh-agent with the following command:

```bash
ssh-add ~/.ssh/id_rsa
```

### Test Node Connections with Ansible Ad-Hoc Commands

You can verify connections to both the managing node (probably your `localhost`) and managed
nodes using Ansible's `ping` module:

Managing Node:

```bash
./pw pdm run --venv in-project ansible localhost -m ping
```

Managed Node:

```bash
./pw pdm run --venv in-project ansible unprovisioned_yoshimo -m ping
```

> \[!TIP\]
> See [`inventory.yml`](./inventory.yml) for other managed nodes.

## Ansible Role: Security

To run this role, your playbook must include the following:

- **Elevated privileges:** Set `become: yes` to execute tasks requiring administrative access.
- **Collect system information:** Set `gather_facts: yes` to collect essential system
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
