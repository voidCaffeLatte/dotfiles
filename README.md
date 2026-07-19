## Prerequisites

Install the following manually before the initial setup:

- [WezTerm](https://wezterm.org/installation.html) - Terminal emulator

## Initial setup

### 1. Install Nix

Install Nix using the community-maintained [Nix Installer](https://github.com/NixOS/nix-installer), with `nix-command` and flakes enabled:

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

Restart the terminal after the installer finishes, then confirm that Nix is available:

```sh
nix --version
```

### 2. Clone this repository

The repository must be located at `~/dotfiles` because out-of-store symlinks resolve configuration files from that path.

```sh
git clone https://github.com/voidCaffeLatte/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Activate Home Manager

Use `nix run` for the first activation. The backup extension prevents existing configuration files from being overwritten.

```sh
nix run github:nix-community/home-manager -- \
  switch --flake .#default --impure -b hm-backup
```

For subsequent configuration changes, run the installed Home Manager command from this repository:

```sh
home-manager switch --flake .#default --impure
```

## Updating

Update the locked Nixpkgs and Home Manager inputs, then activate the new generation:

```sh
nix flake update
home-manager switch --flake .#default --impure
```
