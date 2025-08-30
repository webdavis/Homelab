default:
    @just --choose

alias p := ansible-ping
alias g := ansible-gather-facts
alias l := ansible-lint
alias c := ansible-list-collections
alias t := ansible-playbook-test
alias d := ansible-playbook-devboards

ansible-ping target='unprovisioned_yoshimo':
    ./pw pdm run --venv in-project ansible {{ target }} -m ping

ansible-gather-facts target='unprovisioned_yoshimo':
    ./pw pdm run --venv in-project ansible {{ target }} -m setup

ansible-vault-encrypt target:
    ./pw pdm run --venv in-project ansible-vault encrypt {{ target }}

ansible-playbook-test:
    ./pw pdm run --venv in-project ansible-playbook devboards.yml --tags "test"

ansible-lint:
    ./pw pdm run --venv in-project ansible-lint

ansible-list-collections:
    ./pw pdm run --venv in-project ansible-galaxy collection list

ansible-playbook-devboards:
    ./pw pdm run --venv in-project ansible-playbook devboards.yml
