# Bootstrap

## Talos

### Generate Talos Secrets

```
task talos:generate-secret
task talos:generate-config
```

### Boostrap Talos 🍿

```
task talos:bootstrap
```

### Verify EFI Boot Order

```
task kubernetes:privileged node=...
apk add efibootmgr;
efibootmgr;
efibootmgr --create --disk /dev/nvme0n1 --part 1 -l "\EFI\BOOT\BOOTX64.EFI" --label "Talos Linux" --unicode;
```
