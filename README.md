<p align="center">
    <img src="./gallery/homelab-icon-1.png" alt="Homelab Icon" width="400" height="400">
</p>

# Homelab

This repository automates my home network setup. This automation is hardware-agnostic, but I
like to run it on small single-board computers like Raspberry Pis.

Think: small computers, big network!

## Table of Contents

<!-- table-of-contents GFM -->

- [Project Goals](#project-goals)
- [Technologies Used](#technologies-used)
- [Development Environment](#development-environment)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Set the Python Version](#2-set-the-python-version)
  - [3. Install Project Dependencies](#3-install-project-dependencies)
  - [4. Setup Credentials](#4-setup-credentials)
    - [ssh-agent](#ssh-agent)
    - [Ansible Vault Password](#ansible-vault-password)
  - [5. Verify Ansible Connection](#5-verify-ansible-connection)
- [Ansible Roles](#ansible-roles)
  - [Security](#security)
- [Problems & Solutions](#problems--solutions)
  - [I Upgraded Homebrew and it Broke my Python Virtual Environment](#i-upgraded-homebrew-and-it-broke-my-python-virtual-environment)
    - [Problem](#problem)
    - [Cause](#cause)
    - [Solution](#solution)

<!-- table-of-contents -->

## Project Goals

This project aims to:

- [ ] Maintain a test environment that mirrors my home network for fast, safe deployment.
- [ ] Deploy across multiple operating-systems and CPU architectures.
- [ ] Support both on-metal and cloud deployments.
- [ ] Ensure cross-OS service interoperability.
- [ ] Track [Ansible](https://www.ansible.com/) and [Salt](https://github.com/saltstack/salt)
  configurations in parallel project branches for comparison.

## Technologies Used

Homelab makes use of the following tools:

- **[Ansible](https://www.ansible.com/):** Playbooks to configure services on each device.
- **[Docker](https://docs.docker.com/get-started/):** Containers that run and manage the
  services.
- **Wrapper Scripts:** Simplify working with Ansible and other tools in this project.

## Development Environment

Follow these steps to ensure your environment is ready to work on this project:

### 1. Prerequisites

> If this is your first time working on this project, follow the instructions in
> [macos-dev-environment.md](./docs/macos-dev-environment.md) first.
>
> The instructions below assume you've done this.

In short, this project requires Python 3 and uses a
[Pyprojectx](https://github.com/pyprojectx/pyprojectx) /
[Poetry](https://github.com/python-poetry/poetry) combo to manage Ansible and related tools.

### 2. Set the Python Version

This project uses [pyenv](https://github.com/pyenv/pyenv) to manage and track its Python
version. The current version is specified in the [`.python-version`](./.python-version) file.

Run this command to activate pyenv in your current shell:

```bash
eval "$(pyenv init -)"
```

Once pyenv is activated, it reads the `.python-version` file and activates the Python version
specified there.

> [!Important]
>
> - This command must be run **every time you start a new terminal session** before working on
>   this project.
> - You can run this command from any folder in the project.

### 3. Install Project Dependencies

This project uses Pyprojectx and Poetry to manage Python dependencies in a consistent, isolated
environment:

- **Pyprojectx:** Provides the [`./pw`](./pw) wrapper script, ensuring all project tools run
  consistently without needing global installations (including Poetry).
- **Poetry:** manages the Python dependencies used by this project (including Ansible).

Install the dependencies:

```bash
./pw poetry install
```

**Tip:** Make sure you're using the project's Poetry, not a system-wide one:

```bash
./pw which poetry
```

> The output should point to a path like:\
> `<path_to_this_project>/Homelab/.pyprojectx/venvs/main-ab061d9d4f9bea1cc2de64816d469baf-py3.13/bin/poetry`

> [!TIP] Having trouble? Check the [Problems and Solutions](#problems-and-solutions) section.

### 4. Setup Credentials

#### ssh-agent

Ansible uses SSH to connect to managed nodes.

To avoid repeatedly entering the private key passphrase, load your SSH private key into
ssh-agent:

```bash
ssh-add ~/.ssh/id_rsa
```

> _Other tools may provide an ssh-agent service. I personally use
> [KeePassXC](https://keepassxc.org/)._

#### Ansible Vault Password

Homelab manages secrets with
[Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/vault_using_encrypted_content.html)
Before executing any Playbooks, Ansible ensures it can access the vault.

Ansible Vault fetches the vault password using the \[`vault.password.py`\](./vault.password.py
script, which reads it from the `ANSIBLE_VAULT_PASSWORD` environment variable.

You can set this variable permanently by adding the following to your shell configuration file
(e.g., `~/.bashrc`):

```bash
export ANSIBLE_VAULT_PASSWORD='xxxxxxxxxxxxxx'
```

Alternatively, you can create a `vault.secret` file with the following contents:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='xxxxxxxxxxxxxx'
```

Then, load it into your current shell session with:

```bash
source vault.secret
```

### 5. Verify Ansible Connection

Before you do anything else, verify that you can connect to both the managing node (your
`localhost`) and a managed node using Ansible's `ping` module:

**Managing Node:**

```bash
./pw poetry run ansible localhost -m ping
```

**Managed Node:**

```bash
./pw poetry run ansible unprovisioned_yoshimo -m ping
```

> [!TIP] See [`inventory.yml`](./inventory.yml) for other managed nodes.

Now you should be good to go!

Follow these steps every time you return to the project. Once done, you’re ready to run Ansible
plays or work on the project safely.

## Ansible Roles

This project uses the following Ansible roles. Most of these will eventually be moved to their
own repositories.

### Security

To run this role, your playbook must include the following:

- `become: yes`: required to execute tasks requiring administrative access.
- `gather_facts: yes`: to collect essential system details before executing tasks.

For example:

```yaml
- name: Configure security settings
  hosts: yoshimo
  become: yes
  gather_facts: yes
  tasks:
    - name: Import security role
      ansible.builtin.import_role:
        name: security
```

## Problems & Solutions

### I Upgraded Homebrew and it Broke my Python Virtual Environment

#### Problem

After updating Homebrew, your `.pyprojectx/` environment may break. For example you might get a
`dyld` error like this one:

```bash
$ ./pw poetry run ansible unprovisioned_yoshimo -m ping

dyld[74408]: Library not loaded: /opt/homebrew/Cellar/python@3.13/3.13.5/Frameworks/Python.framework/Versions/3.13/Python
...
```

#### Cause

The `.pyprojectx/` environment was created _before the correct Python version was activated
with pyenv_, so it linked to a Homebrew-managed Python that may no longer exist after the
update.

#### Solution

Rebuild the `.pyprojectx/` environment using the correct Python version.

1. Remove the broken environment:

```bash
rm -rf .pyprojectx/
```

2. Activate the shell environment for pyenv:

```bash
eval "$(pyenv init -)"
```

3. Recreate the environment:

```bash
pyprojectx bootstrap
```

After this, your Python virtual environment will use the pyenv-managed Python, resolving the
Homebrew-related break.
