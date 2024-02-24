default: ansible-ping-servers

alias p := ansible-ping
alias g := ansible-gather-facts
alias l := ansible-lint
alias c := ansible-list-collections

ansible-ping target='servers':
    ./pw pdm run --venv in-project ansible {{target}} -m ping

ansible-gather-facts target='servers':
    ./pw pdm run --venv in-project ansible {{target}} -m setup

ansible-lint:
    ./pw pdm run --venv in-project ansible-lint

ansible-list-collections:
    ./pw pdm run --venv in-project ansible-galaxy collection list
