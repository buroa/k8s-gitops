// Torrent content layout: Original
// Default Torrent Management Mode: Automatic
// Default Save Path: /media/downloads/torrents/complete
// Incomplete Save Path: /media/downloads/torrents/incomplete

module.exports = {
  action: "inject",
  apiKey: process.env.CROSS_SEED_API_KEY,
  delay: 30,
  duplicateCategories: true,
  flatLinking: false,
  includeEpisodes: true,
  includeNonVideos: true,
  includeSingleEpisodes: true,
  linkCategory: "cross-seed",
  linkDir: "/media/downloads/torrents/complete/cross-seed",
  linkType: "hardlink",
  matchMode: "safe",
  outputDir: "/config",
  qbittorrentUrl: "http://qbittorrent.media.svc.cluster.local:8080",
  skipRecheck: true,
  torrentDir: "/config/qBittorrent/BT_backup",
  torznab: [], // Only using annoucements from autobrr
};
