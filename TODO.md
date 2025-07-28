# Home-Ops TODO

## In Progress

### qBittorrent Tools Migration (feat/qbittorrent-tools-tqm-qbr)
- [x] Remove existing qbtools configuration
- [x] Create qbr (qBittorrent Reannounce) configuration  
- [x] Create tqm (Torrent Queue Manager) configuration
- [x] Update tools kustomization.yaml to reference new tools
- [ ] **Configure secrets for qBittorrent password and Radarr API key in tqm config**

## Pending

### Cherry-pick Analysis: qbittorrent-cli Configuration (Issue #4)
- [ ] **NOT RECOMMENDED for cherry-pick** - requires manual migration due to structural conflicts
- [ ] Evaluate adding qbittorrent-cli config (.qbt.toml) to current qBittorrent setup
- [ ] Consider restructuring tqm from tools/ to standalone app if needed
- [ ] Review removal of qbr tool and assess impact

## Completed