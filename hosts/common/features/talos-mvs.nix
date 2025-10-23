{
  config,
  pkgs,
  ...
}: let
  createTalosVM = {
    name,
    memory,
    vcpus,
    diskSize,
    mac,
  }: let
    diskPath = "/var/lib/libvirt/images/talos/${name}.qcow2";
  in {
    name = "create-${name}";
    value = {
      description = "Create Talos VM ${name}";
      wantedBy = ["multi-user.target"];
      after = ["libvirtd.service"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Create disk if it doesn't exist
        if [ ! -f ${diskPath} ]; then
          ${pkgs.qemu}/bin/qemu-img create -f qcow2 ${diskPath} ${diskSize}
        fi

        # Check if VM exists
        if ! ${pkgs.libvirt}/bin/virsh list --all | grep -q "${name}"; then
          # Create VM
          ${pkgs.virt-manager}/bin/virt-install \
            --name ${name} \
            --memory ${toString memory} \
            --vcpus ${toString vcpus} \
            --disk path=${diskPath},bus=virtio \
            --network bridge=br0,mac=${mac},model=virtio \
            --cdrom ~/Downloads/talos-v1.8.1.iso \
            --boot uefi \
            --graphics none \
            --console pty,target_type=serial \
            --noautoconsole \
            --os-variant linux2022
        fi
      '';
    };
  };

  vms = [
    {
      name = "talos-cp-1";
      memory = 4096;
      vcpus = 2;
      diskSize = "20G";
      mac = "52:54:00:00:01:01";
    }
    {
      name = "talos-worker-1";
      memory = 4096;
      vcpus = 2;
      diskSize = "60G";
      mac = "52:54:00:00:01:02";
    }
    {
      name = "talos-worker-2";
      memory = 4096;
      vcpus = 2;
      diskSize = "60G";
      mac = "52:54:00:00:01:03";
    }
  ];
in {
  systemd.services = builtins.listToAttrs (map createTalosVM vms);
}
