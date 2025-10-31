# macOS Dev Environment Installation and Setup

<!-- table-of-contents GFM -->

- [Flashing Raspberry Pi OS](#flashing-raspberry-pi-os)
  - [Install Raspberry Pi Imager](#install-raspberry-pi-imager)
  - [Stub your Secrets](#stub-your-secrets)
  - [Download the Image](#download-the-image)
  - [Attach Storage Device](#attach-storage-device)
  - [Flash the Image](#flash-the-image)
  - [Eject](#eject)
  - [Bonus: Justfile Shortcuts](#bonus-justfile-shortcuts)
    - [Install just](#install-just)
    - [download-image](#download-image)
    - [flash](#flash)
  - [Boot the Pi](#boot-the-pi)
- [Development Environment Setup](#development-environment-setup)
  - [pyenv](#pyenv)
  - [Bonus: Install direnv](#bonus-install-direnv)
  - [Install Project Dependencies](#install-project-dependencies)
  - [ssh-agent](#ssh-agent)
- [Verify Ansible Connection](#verify-ansible-connection)

<!-- table-of-contents -->

## Flashing Raspberry Pi OS

### Install Raspberry Pi Imager

```bash
brew install --cask raspberry-pi-imager
```

### Stub your Secrets

Add your sensitive information to the variables in [`vault.secrets`](../vault.secrets):

```bash
#!/usr/bin/env bash

export ANSIBLE_VAULT_PASSWORD=''
export PUBLIC_SSH_KEY=''
export PI_HOSTNAME='raspberrypi'
export PI_USERNAME='pi'
# This is the default Raspberry Pi password ('raspberry') hashed using crypt SHA-256 ($5$).
export PI_PASSWORD_HASH='$5$.yEhkKP.78$j2APhF51Ok.r.tC/wPrtEnnF2uJK4Z.BRRiCLJbgEk9'
```

Then source the file so that the variables are available in your current shell:

```bash
source vault.secrets
```

### Download the Image

Run the Python helper script to get the lastest Raspberry Pi OS Lite URL:

```bash
./scripts/get-latest-raspios-lite-image-url.py
```

> **Example output:**
>
> ```console
> Supported Devices:
>   - pi5-64bit
>   - pi4-64bit
>   - pi3-64bit
>
> Latest Raspberry Pi OS Lite (64-bit) Image URL:
>   - https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-10-02/2025-10-01-raspios-trixie-arm64-lite.img.xz
> ```

Download the image with `curl`

```bash
curl -O https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-10-02/2025-10-01-raspios-trixie-arm64-lite.img.xz
```

or with [HTTPie](https://github.com/httpie/cli) (`brew install httpie`):

```bash
https --download https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-10-02/2025-10-01-raspios-trixie-arm64-lite.img.xz
```

### Attach Storage Device

Plug a MicroSD card (or some other storage device) into your host machine. You can locate the
block device using `diskutil list`.

For example, my `32 GB` MicroSD card is attached to `/dev/disk60`:

```bash
$ diskutil list
/dev/disk60 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *32.0 GB    disk60
   1:             Windows_FAT_32 bootfs                  536.9 MB   disk60s1
   2:                      Linux                         2.4 GB     disk60s2
                    (free space)                         29.1 GB    -
```

### Flash the Image

From the project root folder, run the following command to flash the image to your storage
device:

```bash
/Applications/Raspberry\ Pi\ Imager.app/Contents/MacOS/rpi-imager \
    --cli \
    --debug \
    --first-run-script scripts/firstrun.sh \
    2025-10-01-raspios-trixie-arm64-lite.img.xz \
    /dev/disk60
```

> [!NOTE]
>
> 1. Replace `/dev/disk60` with the actual device identifier of your storage media.
> 1. `rpi-imager` will prompt you for your password to allow it to write to your storage
>    device. Enter it and watch it go to work.

### Eject

Once the flashing process completes, eject the device:

```bash
diskutil eject /dev/disk60
```

Now you can unplug the MicroSD card from your host machine and insert it into your Raspberry
Pi.

### Bonus: Justfile Shortcuts

This project provides a [`justfile`](../justfile) with some
[just](https://github.com/casey/just) shortcuts to automate some of the previous steps.

#### Install just

```bash
brew install just
```

#### download-image

```bash
just download-image
```

> If the image already exists in the project root, this command will skip downloading.

#### flash

Flash the image (assuming you have configured your secrets):

```bash
just flash /dev/disk60
```

> [!NOTE]
>
> - If you don’t provide a block device, `flash` will prompt you to enter one.
>   - ⚠️ Make sure to provide the correct block device to avoid overwriting other drives.
> - If the Raspberry Pi OS image hasn’t been downloaded yet, `flash` will automatically
>   download it first.

### Boot the Pi

1. Link your Raspberry Pi to your router using an Ethernet cable
   - (If you configured networking during the flashing process, this step can be skipped.)
1. Connect your Raspberry Pi to a power source and it should boot!

## Development Environment Setup

To get started on this project, a few tools must be installed on your development machine.

> [!NOTE]
>
> This document assumes that you are using an Apple Computer running at least macOS Sequoia
> `version 15.5+`.
>
> This probably works on earlier Mac OS versions, but I've only tested it on versions later
> than the one listed above 🤷🏼‍.

### pyenv

It's recommended to use [pyenv](https://github.com/pyenv/pyenv) to manage Python versions.

Install it with Homebrew:

```bash
brew install pyenv
```

Install the Python version tracked in [`.python-version`](../.python-version):

```bash
cat .python-version | pyenv install
```

Now switch to that Python version, like so:

```bash
eval "$(pyenv init -)"
```

### Bonus: Install direnv

This project comes with a [`.envrc`](../.envrc) file.

[direnv](https://direnv.net/) provides the ability to automatically source this file, which
sets the Python environment without having to run `eval "$(pyenv init -)"` every time you open
a new terminal.

Install `direnv`:

```bash
brew install direnv
```

Then allow direnv to use the `.envrc` file:

```bash
dirven allow
```

### Install Project Dependencies

This project uses Poetry to manage its Python dependencies, but there's no need to
install it. Everything is handled by [Pyprojectx](https://pyprojectx.github.io/), an
all-inclusive bootstrapping tool, which provides the `pw` script.

Simply run the following command to ensure everything is in working order (`pyprojectx` will do
the heavy lifting for you):

```bash
./pw poetry sync
```

> [!NOTE]
>
> Poetry settings and top-level dependencies are defined in the
> [pyproject.toml](../pyproject.toml).

### ssh-agent

Ansible connects to managed nodes via SSH.

Assuming you enabled SSH and added your SSH public key to your Raspberry Pi OS image, load
your SSH private key into `ssh-agent`:

```bash
ssh-add ~/.ssh/id_rsa
```

## Verify Ansible Connection

Use the following ad hoc Ansible command to ping the control node (probably your `localhost`)
and verify the connection:

```bash
./pw poetry run ansible localhost -m ping
```

Then ping the managed node:

```bash
./pw poetry run ansible pi -m ping
```

> [!NOTE]
>
> All of the nodes managed by this project can be found in the
> [`inventory.yml`](../inventory.yml) file.
