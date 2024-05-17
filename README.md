**NIX-CONFIG**
===============

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

_How to update your home manager?_

###Step 4: Update your Home Manager configuration and create a backup. This changes doesn't need to reboot to apply the changes.
```bash
home-manager switch --flake . -b backup
```

## Changing the configuration

- Adding a new package in common file, [common.nix](./home/nainai/common.nix)
- Adding a new package in nixos file, [nixos.nix](./home/nainai/nixos.nix)
