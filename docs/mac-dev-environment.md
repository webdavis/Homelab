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

### Test the connection via an Ansible ad-hoc command

Ping the control node (probably your `localhost`) to verify the connection:

```bash
pdm run --venv in-project ansible localhost -m ping
```

> [!NOTE]
> All of the nodes managed by this project are provided in [hosts.ini](../hosts.ini).

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

## Booting your Raspberry Pi

Once `dd` finishes eject the disk:

```bash
diskutil eject /dev/disk6
```

Then unplug your MicroSD card from you host machine and insert it into the Raspberry Pi's
MicroSD card slot.

Connect your Raspberry Pi to power and it should boot!
