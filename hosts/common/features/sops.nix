{
  config,
  pkgs,
  ...
}: {
  # ────────────────────────────────────────────────────────────
  # SOPS Configuration
  # ────────────────────────────────────────────────────────────
  # Secrets are encrypted with age and stored in secrets/secrets.yaml
  # The age key is derived from the SSH host key

  # Ensure sops-nix is available
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  # Configure sops for system-level secrets (if needed)
  # Most secrets should be configured in home-manager
  sops = {
    # Use age key for encryption/decryption
    # The age key will be generated from SSH keys
    age = {
      # Use SSH host key for age encryption
      # This will be converted to an age key automatically
      keyFile = "/etc/ssh/ssh_host_ed25519_key";

      # Alternatively, you can specify a dedicated age key file
      # keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
