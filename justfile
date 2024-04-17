default:
    @just --choose

alias p := ansible-ping
alias g := ansible-gather-facts
alias l := ansible-lint
alias c := ansible-list-collections

ansible-ping target='unconfigured_nodes':
    ./pw pdm run --venv in-project ansible {{ target }} -m ping

ansible-gather-facts target='new_bob':
    ./pw pdm run --venv in-project ansible {{ target }} -m setup

ansible-lint:
    ./pw pdm run --venv in-project ansible-lint

ansible-list-collections:
    ./pw pdm run --venv in-project ansible-galaxy collection list
