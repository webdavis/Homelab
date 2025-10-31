# Task List

## Development Environment

- [ ] Replace Pyprojectx/Poetry combo with a Nix flake. Nix flakes provide immutable environments by
  default, which means no more dependency management hell. Ref:
  [sierras-macOS-backup/flake.nix](https://github.com/webdavis/sierras-macOS-backup/blob/main/flake.nix)
- [ ] Create Ansible Role [devenv](../roles/devenv/) to automate the developement environment setup for
  this project
