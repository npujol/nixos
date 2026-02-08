# NIX-CONFIG

This repository contains the nixos configuration from my laptop.

## Setup

### Step 1: Clone the repository

```bash
git clone git@github.com:npujol/nixos.git
```

### Step 2: Go into the repository folder

```bash
cd nixos
```

_How to update your system?_

### Step 3: Build the system configuration from a flake in the current directory and schedules it to be applied at the next reboot

```bash
sudo nixos-rebuild boot --flake .
```

This change automatically to the new version of the system.

```bash
sudo nixos-rebuild switch --flake .  
```

_How to update your home manager?_

### Step 4: Update your Home Manager configuration and create a backup. This changes doesn't need to reboot to apply the changes

```bash
home-manager switch --flake . -b backup
```

- Update flake lock. All inputs will be updated.

```bash
nix flake update
```

## Changing the configuration

- Adding a new package in common file, [common.nix](./home/nainai/common.nix)
- Adding a new package in nixos file, [nixos.nix](./home/nainai/nixos.nix)
- Adding a new package in limbo file, [limbo.nix](./home/nainai/limbo.nix)

## First steps using nixos

- Run nix-shell use flake and home-manager

```bash
nix-shell
```

# TODO

- [ ] move headscale to server
