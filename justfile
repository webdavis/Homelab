default:
    @just --choose

alias p := ansible-ping
alias g := ansible-gather-facts
alias ve := ansible-vault-edit
alias l := ansible-lint
alias c := ansible-list-collections
alias b := ansible-playbook-bootstrap

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
