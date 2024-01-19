# Bootstrap

## Talos

### Create Talos Secrets

```
task talos:gensecret
task talos:genconfig
```

### Boostrap Talos

```
task talos:bootstrap
task talos:kubeconfig
```

### Bootstrap Extras

```
task talos:apply-extras
```

### Update Mac EFI

_use reFINd ensure boot order and delete other boot entries_

1. Download [refind](https://sourceforge.net/projects/refind/files/0.14.0/refind-flashdrive-0.14.0.zip/download) here
2. Add [exfat_x64.efi](https://github.com/pbatard/efifs/releases/download/v1.9/exfat_x64.efi) driver
3. Set boot order to Talos: `bcfg boot add 0 fs1:\EFI\BOOT\BOOTX64.efi "Talos"`

If you don't do this, your system reboots will be _extremely_ slow.
