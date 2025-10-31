default:
    @just --choose

alias b := ansible-playbook-bootstrap
alias c := ansible-list-collections
alias d := download-image
alias f := flash
alias g := ansible-gather-facts
alias l := ansible-lint
alias p := ansible-ping
alias ve := ansible-vault-edit

# Use Bash to execute all recipes.

set shell := ["bash", "-cu"]

downloader := `if command -v https >/dev/null 2>&1; then echo "https --download"; else echo "curl -O"; fi`
raspios_lite_image := "2025-10-01-raspios-trixie-arm64-lite.img.xz"
image_url := "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-10-02/{{raspios_lite_image}}"
rpi_imager := "/Applications/Raspberry Pi Imager.app/Contents/MacOS/rpi-imager"

download-image:
    [ ! -f "{{ raspios_lite_image }}" ] && {{ downloader }} {{ image_url }}

check-rpi-imager:
    #!/usr/bin/env bash
    if [ ! -x "{{ rpi_imager }}" ]; then
        echo "Terminating: Raspberry Pi Imager CLI not found at {{ rpi_imager }}." >&2
        echo "Please install it before running flash. For example: brew install --cask raspberry-pi-imager" >&2
        exit 1
    fi

flash target_disk=`read -p "Enter target storage device (e.g., /dev/disk60): " disk; echo $disk`: check-rpi-imager download-image
    {{ rpi_imager }} \
        --cli \
        --debug \
        --first-run-script scripts/firstrun.sh \
        {{ raspios_lite_image }} \
        {{ target_disk }}

ansible-ping target='unprovisioned_yoshimo':
    ./pw poetry run ansible {{ target }} -m ping

ansible-gather-facts target='unprovisioned_yoshimo':
    ./pw poetry run ansible {{ target }} -m setup

ansible-vault-edit target:
    ./pw poetry run ansible-vault edit {{ target }}

ansible-vault-encrypt target:
    ./pw poetry run ansible-vault encrypt {{ target }}

ansible-lint:
    ./pw poetry run ansible-lint

ansible-list-collections:
    ./pw poetry run ansible-galaxy collection list

ansible-playbook-bootstrap:
    ./pw poetry run ansible-playbook bootstrap.yml
