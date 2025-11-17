// Torrent content layout: Original
// Default Torrent Management Mode: Automatic
// Default Save Path: /media/downloads/torrents/complete
// Incomplete Save Path: /incomplete

module.exports = {
  action: "inject",
  apiKey: process.env.CROSS_SEED_API_KEY,
  linkCategory: "cross-seed",
  linkDirs: ["/media/downloads/torrents/complete/cross-seed"],
  linkType: "hardlink",
  matchMode: "partial",
  outputDir: null,
  port: Number(process.env.CROSS_SEED_PORT),
  skipRecheck: true,
  torrentClients: ["qbittorrent:http://qbittorrent.media.svc.cluster.local"],
  torznab: [],
  useClientTorrents: true,
};
