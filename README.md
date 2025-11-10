<p align="center">
    <img src="./gallery/homelab-icon-1.png" alt="Homelab Icon" width="400" height="400">
</p>

# Homelab

This repo automates my home network setup. This automation is hardware-agnostic, but I like to run it on
small single-board computers like Raspberry Pis.

Think: small computers, big network!

## Table of Contents

<!-- table-of-contents GFM -->

- [Project Goals](#project-goals)
- [Technologies Used](#technologies-used)
- [Development Environment](#development-environment)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Project Dependencies](#2-project-dependencies)
  - [3. Credentials](#3-credentials)
    - [ssh-agent](#ssh-agent)
    - [Ansible Vault Password](#ansible-vault-password)
  - [4. Verify Ansible Connection](#4-verify-ansible-connection)
- [Ansible Roles](#ansible-roles)
  - [Security](#security)

<!-- table-of-contents -->

## Project Goals

This project aims to:

- [ ] Come with batteries included so that setup is quick and easy.
- [ ] Maintain a test environment that mirrors my home network for fast, safe deployment.
- [ ] Deploy across multiple operating-systems and CPU architectures.
- [ ] Support both on-metal and cloud deployments.
- [ ] Ensure cross-OS service interoperability.
- [ ] Track [Ansible](https://www.ansible.com/) and [Salt](https://github.com/saltstack/salt)
  configurations in parallel project branches for comparison.

## Technologies Used

Homelab makes use of the following tools:

- **[Ansible](https://www.ansible.com/):** playbooks to configure services on each device.
- **[Docker](https://docs.docker.com/get-started/):** containers that run and manage the services:
  - **[webdavis/docker-raspios-lite](https://github.com/webdavis/docker-raspios-lite):** a hand spun
    Raspberry Pi OS Lite Docker Image
- **[Scripts](./scripts):** these simplify working with Ansible and other tools in this project.

## Development Environment

This project uses [uv](https://docs.astral.sh/uv/) to manage Python, Ansible, and related tools.

Follow these steps to ensure your environment is ready to work on this project:

### 1. Prerequisites

> [!Tip]
>
> If this is your first time working on this project, follow the instructions in
> [macos-dev-environment.md](./docs/macos-dev-environment.md) first.
>
> The instructions below assume you've done this.

### 2. Project Dependencies

This project uses uv to manage Python dependencies in a consistent, isolated environment:

Install them like so:

```bash
uv sync
```

Verify they are available:

```bash
$ uv which ansible
<path_to_this_project>/Homelab/.venv/bin/ansible
```

### 3. Credentials

#### ssh-agent

Ansible uses SSH to connect to managed nodes.

To avoid repeatedly entering the private key passphrase, load your SSH private key into ssh-agent:

```bash
ssh-add ~/.ssh/id_rsa
```

> _Other tools may provide an ssh-agent service. I personally use [KeePassXC](https://keepassxc.org/)._

#### Ansible Vault Password

Homelab uses
[Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/vault_using_encrypted_content.html)
to managed its secrets. Before executing any Playbooks, Ansible will check that it can access the vault.

Ansible Vault fetches the vault password using the \[`vault.password.py`\](./vault.password.py) script,
which locates it using the `ANSIBLE_VAULT_PASSWORD` environment variable.

You can set this variable permanently by adding the password in the `vault.secret` file:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='xxxxxxxxxxxxxx'
```

If you aren't using `direnv`, then load it into your current shell session like so:

```bash
source vault.secrets
```

### 4. Verify Ansible Connection

Before you do anything else, verify that you can connect to both the managing node (your `localhost`) and
a managed node using Ansible's `ping` module:

**Manager Node:**

```bash
uv run ansible localhost -m ping
```

**Managed Node:**

```bash
uv run ansible unprovisioned_yoshimo -m ping
```

> [!Tip]
>
> See [`inventory.yml`](./inventory.yml) for other managed nodes.

Now you should be good to go!

Follow these steps every time you return to the project. Once done, you’re ready to run Ansible plays or
work on the project safely.

## Ansible Roles

This project uses the following Ansible roles. Most of these will eventually be moved to their own
repositories.

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
