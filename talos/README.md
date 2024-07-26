# Bootstrap Secrets and Config

```sh
task talos:generate-secret
task talos:generate-config
```

# Verify EFI Boot Order

```sh
task kubernetes:privileged node=...
apk add efibootmgr;
efibootmgr;
efibootmgr --create --disk /dev/nvme0n1 --part 1 -l "\EFI\BOOT\BOOTX64.EFI" --label "Talos Linux" --unicode;
```
