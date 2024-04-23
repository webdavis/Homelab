default:
    @just --choose

alias p := ansible-ping
alias g := ansible-gather-facts
alias l := ansible-lint
alias c := ansible-list-collections
alias d := ansible-playbook-devboards

ansible-ping target='mister':
    ./pw pdm run --venv in-project ansible {{ target }} -m ping

ansible-vault-encrypt target:
    ./pw pdm run --venv in-project ansible-vault encrypt {{ target }}

ansible-gather-facts target='new_bob':
    ./pw pdm run --venv in-project ansible {{ target }} -m setup

ansible-lint:
    ./pw pdm run --venv in-project ansible-lint

ansible-list-collections:
    ./pw pdm run --venv in-project ansible-galaxy collection list

ansible-playbook-devboards:
    ./pw pdm run --venv in-project ansible-playbook devboards.yml
