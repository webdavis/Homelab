# Mac OS Dev Environment Installation and Setup

To get started on this project, a few tools must be installed on your development machine.

This document assumes that you are using a Apple Computer running at least Mac OS Sonoma Sonoma
14.2 (23C64).

> [!WARNING]
> This probably works on earlier Mac OS versions? I have only tested it on the version listed
> above :man-shrugging:.

## pyenv

It's recommended to use [pyenv](https://github.com/pyenv/pyenv) to manage Python versions.

Install it with Homebrew:

```bash
brew update
brew install pyenv
```

Install the version of Python tracked in [`.python-version`](../.python-version):

```bash
cat .python-version | pyenv install
```

Now switch to that version, like so:

```bash
eval "$(pyenv init -)"
```

## PDM

Install PDM using Homebrew, like so:

```bash
brew install pdm
```

Install the Bash completions:

```bash
pdm completion bash > /etc/bash_completion.d/pdm.bash-completion
```

### Install this projects Dependencies

PDM makes use of the [pyproject.toml](./pyproject.toml) to manage dependencies. Install them by
running this command:

```bash
pdm sync
```

## Running the Ansible Plays

Ansible connects to managed nodes via SSH. If you have already pasted your configured SSH
public key on your Raspberry Pi when you flashed the Image using Raspberry Pi Imager, you can
load the corresponding SSH private key into `ssh-agent` by running the following command:

```bash
ssh-add ~/.ssh/id_rsa
```

### Set the Ansible Vault password

The `vault.password.py` file uses the `ANSIBLE_VAULT_PASSWORD` environment variable to decrypt
Ansible Vault files in this project. It's recommended to create an `ansible.vault` file in the
root of this project, with the following contents:

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD='secret_vault_password'
```

Next, in the same terminal window you're using for this project, source the file:

```bash
source vault.password
```

> [!CAUTION]
> If you don't set the `ANSIBLE_VAULT_PASSWORD` environment variable then Ansible will print
> the following error message to the console: **`ERROR! Decryption failed`**

### Create your own Ansible Vault files for this project

You will need to create `vault.yml` files for each managed node in this project.

#### 1st Device: The Development Computer

In the `host_vars/subdomain.domain.tld/main.yml` (e.g.
`host_vars/maeve.netdavis.net/main.yml`) file, change the value of the
`account.localuser.username` variable to your current username. For example:

```yaml
---

account:
  localuser:
    username: stephen
```

Then copy and paste the following file contents into `host_vars/subdomain.domain.tld/vault.yml`
(e.g. `host_vars/maeve.netdavis.net/vault.yml`):

```yaml
---

vault_account:
  root:
    password: <create a strong root account password and put it here>
  localuser:
    password: <create a strong user account password and put it here>
    ssh_key:
      public: <put your SSH Public Key here>
      private: |
        <put your SSH Private Key here>
```

Then use Ansible Vault to encrypt the file, like this:

```bash
pdm run --venv in-project ansible-vault encrypt host_vars/subdomain.domain.tld/vault.yml
```

Finally, add your development computer to the `[devenv]` group in the
[hosts.ini](../hosts.ini) file, like so:

```ini
[devenv]

maeve.netdavis.net ansible_user=stephen private_ip=192.168.12.162 private_ip_interface=en0 ansible_port=6040
```

#### 2nd Device: The Target Server

Copy and paste the following file contents into the `group_vars/all/vault.yml`:

```yaml
---

vault_account:
  root:
    password: <create a strong root account password and put it here>
  localuser:
    password: <create a strong user account password and put it here>
    ssh_key:
      public: <put your SSH Public Key here>
      private: |
        <put your SSH Private Key here>
```

Then use Ansible Vault to encrypt the file:

```bash
pdm run --venv in-project ansible-vault encrypt group_vars/all/vault.yml
```

Now add your managed node to the `[server]` group in the [`hosts.ini`](../hosts.ini) file:

```ini
[server]

bob.netdavis.net ansible_user=localadmin ansible_ssh_host=192.168.1.171 ansible_port=6040
```

### Test the connection via an Ansible ad-hoc command

Ping the managing node (probably your `localhost`) to verify the connection:

```bash
pdm run --venv ansible localhost -m ping
```

> [!NOTE]
> All of the nodes managed by this project are provided in [`hosts.ini`](../hosts.ini).

## Flashing the Image

Plug a MicroSD card (or some other form of secondary memory) into your host machine. You can
locate the block device using `diskutil list` (e.g. `/dev/disk6`).

Then, from the project root folder, run the following command to flash the newly modified image
to your MicroSD card:

```bash
pv Raspbian.img | sudo dd bs=19M iflag=fullblock conv=fsync of=/dev/disk6
```

> [!TIP]
> Adjust the `bs` operand to the max write speed of your MicroSD card, USB 3.0 device, etc.
