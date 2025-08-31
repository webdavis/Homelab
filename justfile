default:
    @just --choose

alias p := ansible-ping
alias g := ansible-gather-facts
alias ve := ansible-vault-edit
alias l := ansible-lint
alias c := ansible-list-collections
alias b := ansible-playbook-bootstrap

ansible-ping target='unprovisioned_yoshimo':
    ./pw pdm run --venv in-project ansible {{ target }} -m ping

ansible-gather-facts target='unprovisioned_yoshimo':
    ./pw pdm run --venv in-project ansible {{ target }} -m setup

ansible-vault-edit target:
    ./pw pdm run --venv in-project ansible-vault edit {{ target }}

ansible-vault-encrypt target:
    ./pw pdm run --venv in-project ansible-vault encrypt {{ target }}

ansible-lint:
    ./pw pdm run --venv in-project ansible-lint

ansible-list-collections:
    ./pw pdm run --venv in-project ansible-galaxy collection list

ansible-playbook-bootstrap:
    ./pw pdm run --venv in-project ansible-playbook bootstrap.yml
