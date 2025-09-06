<p align="center">
    <img src="./gallery/homelab-icon-1.png" alt="Homelab Icon" width="400" height="400">
</p>

# Homelab

This repository automates my home network setup. The automation is hardware-agnostic, but I
like to run it on small single-board computers like Raspberry Pis.

Think: small computers, big network!

## Table of Contents

- [Technologies Used](#technologies-used)
- [Essential Steps to Run Homelab](#essential-steps-to-run-homelab)
  - [1. Install Prerequisites](#1-install-prerequisites)
  - [2. Activate Python Version with Pyenv](#2-activate-python-version-with-pyevn)
  - [3. Install Dependencies with Pyprojectx & Poetry](#3-install-dependencies-with-pyprojectx--poetry)
    - [3b. Fixing a Broken Virtual Environment](#3b-fixing-a-broken-virtual-environment-after-a-homebrew-update)
  - [4. Load the SSH Key](#4-load-the-ssh-key)
  - [5. Configure and Source an Ansible Vault Password](#5-configure-and-source-an-ansible-vault-password)
  - [6. Verify Node Connections using Ansible Ad-Hoc Commands](#6-verify-node-connections-using-ansible-ad-hoc-commands)
- [Ansible Roles](#ansible-roles)
  - [Security](#security)

## Project Goals

This project aims to:

- [ ] Maintain a test environment that mirrors my home network for fast, safe deployment
- [ ] Deploy across multiple operating-systems and CPU architectures
- [ ] Support both on-metal and cloud deployments
- [ ] Ensure cross-OS service interoperability
- [ ] Track [Ansible](https://www.ansible.com/) and [Salt](https://github.com/saltstack/salt)
  configurations in parallel project branches for comparison

## Technologies Used

Homelab makes use of the following tools:

- **[Ansible](https://www.ansible.com/):** Playbooks to configure services on each device.
- **[Docker](https://docs.docker.com/get-started/):** Containers that run and manage the
  services.
- **Wrapper Scripts:** Simplify working with Ansible and other tools in this project.

## Essential Steps to Run Homelab

Whenever you return to this project, follow these steps first to ensure your environment is in
a clean working state.

### 1. Install Prerequisites

> If this is your first time setting up the development environment, follow the instructions in
> [mac-dev-environment.md](./docs/mac-dev-environment.md) first.
>
> The instructions below assume you've done this.

### 2. Activate Python Version with Pyevn

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

### 3. Install Dependencies with Pyprojectx & Poetry

This project uses [Pyprojectx](https://github.com/pyprojectx/pyprojectx) and
[Poetry](https://github.com/python-poetry/poetry) to manage Python dependencies in a consistent,
isolated environment:

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

#### 3b. Fixing a Broken Virtual Environment After a Homebrew Update

After updating Homebrew, running:

```bash
+❯ ./pw poetry run ansible unprovisioned_yoshimo -m ping
```

may produce a `dyld` error like:

```
dyld[74408]: Library not loaded: /opt/homebrew/Cellar/python@3.13/3.13.5/Frameworks/Python.framework/Versions/3.13/Python
...
```

**Cause:** the `.pyprojectx` environment was boostrapped _before activating pyenv_, so it used
the Homebrew Python path. Then when Homebrew updated, that Python version was removed, breaking
the virtual environment.

**Fix:** Rebuild the `.pyprojectx` environment using pyenv:

```bash
# Activate pyenv:
eval "$(pyenv init -)"

# Remove the broken pyprojectx environment:
rm -rf .pyprojectx/

# Recreate the environment:
pyprojectx bootstrap
```

After this, your virtual environment will use the pyenv-managed Python, avoiding
Homebrew-related breaks.

### 4. Load the SSH Key

Ansible uses SSH to connect to managed nodes.

To avoid repeatedly entering the private key passphrase, load your SSH private key into
ssh-agent with the following command:

```bash
ssh-add ~/.ssh/id_rsa
```

> _Other tools may provide an ssh-agent service. I personally use
> [KeePassXC](https://keepassxc.org/)._

### 5. Configure and Source an Ansible Vault Password

Homelab uses [Ansible
Vault](https://docs.ansible.com/ansible/latest/vault_guide/vault_using_encrypted_content.html)
for managing secrets. Passwords are managed dynamically via
[`vault.password.py`](./vault.password.py), which requires the `ANSIBLE_VAULT_PASSWORD`
environment variable to be set in your current shell.

Create a file `vault.secret` with the following contents:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='xxxxxxxxxxxxxx'
```

Then load it into your shell with:

```bash
source vault.secret
```

### 6. Verify Node Connections using Ansible Ad-Hoc Commands

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

> [!TIP]
> See [`inventory.yml`](./inventory.yml) for other managed nodes.

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
