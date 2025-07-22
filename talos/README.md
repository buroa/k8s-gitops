# Talos Node Type Configuration

This directory contains a dynamic node-type based Talos configuration system that allows you to manage different hardware types with their specific configurations.

## Structure

```
talos/
├── node-types/                    # Hardware-specific configurations
│   ├── NUC7/                     # NUC7 hardware type
│   │   ├── template.j2           # Talos config template
│   │   ├── schematic.yaml        # Hardware-specific extensions
│   │   └── controlplane/         # Node-specific overrides
│   │       └── 10.0.5.123.yaml
│   └── EQ12/                     # EQ12 hardware type
│       ├── template.j2
│       ├── schematic.yaml
│       └── controlplane/
│           ├── 10.0.5.196.yaml
│           └── 10.0.5.78.yaml
├── node-mapping.yaml             # IP → node-type mapping
├── upstream.j2                   # Base template for new node types
├── talosconfig                    # Talos client configuration
└── README.md                     # This file
```

## Key Features

- **Hardware-specific configurations**: Each node type has its own template and schematic
- **Automatic node type detection**: Tasks automatically determine node type from IP address
- **Easy expansion**: Drop in new node types and they're automatically discovered
- **Hardware-specific drivers**: Each node type can have different system extensions

## Usage

### List available node types
```bash
task talos:list-node-types
```

### List all nodes and their types
```bash
task talos:list-nodes
```

### Apply configuration to a node
```bash
task talos:apply-node NODE=10.0.5.123
```
The task will automatically:
1. Look up the node type from `node-mapping.yaml`
2. Use the appropriate template and schematic
3. Apply the configuration

### Add a new node type
```bash
task talos:add-node-type NODE_TYPE=MyNewHardware
```
This creates the folder structure and copies base templates.

### Regenerate schematic for a node type
```bash
task talos:regenerate-schematic NODE_TYPE=NUC7
```

## Adding New Hardware

To add a new hardware type:

1. **Create the node type**:
   ```bash
   task talos:add-node-type NODE_TYPE=MyHardware
   ```

2. **Customize the template**:
   - Edit `node-types/MyHardware/template.j2`
   - Add hardware-specific network configuration (device selectors)
   - Adjust any hardware-specific settings

3. **Update the schematic**:
   - Edit `node-types/MyHardware/schematic.yaml`
   - Add required system extensions (drivers, firmware)
   - Remove unnecessary extensions

4. **Add node mappings**:
   - Edit `node-mapping.yaml`
   - Map IP addresses to the new node type

5. **Add node-specific configs**:
   - Place controlplane configs in `node-types/MyHardware/controlplane/`
   - Name them with the IP address (e.g., `10.0.5.100.yaml`)

## Current Node Types

### NUC7
- **Hardware**: Intel NUC7 with built-in e1000e ethernet + USB r8152 adapter
- **Network**: Bond with device selectors for both interfaces
- **Extensions**: realtek-firmware, i915, intel-ucode, nfsd

### EQ12  
- **Hardware**: EQ12 with dual Intel i225-V (igc driver)
- **Network**: Bond with wildcard device selector for igc interfaces
- **Extensions**: i915, intel-ucode, nfsd

## Device Selectors

Each hardware type uses specific device selectors in their network configuration:

- **NUC7**: Uses exact MAC addresses for built-in and USB ethernet
- **EQ12**: Uses wildcard MAC pattern (`7c:83:34:*`) to match all igc interfaces

This ensures the correct network interfaces are bonded regardless of interface naming.