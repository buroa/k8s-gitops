// Torrent content layout: Original
// Default Torrent Management Mode: Automatic
// Default Save Path: /media/downloads/torrents/complete
// Incomplete Save Path: /media/downloads/torrents/incomplete

module.exports = {
  delay: 20,
  port: process.env.PORT || 2468,
  qbittorrentUrl: "http://qbittorrent.media.svc.cluster.local:8080",

  apiAuth: false,
  action: "inject",
  matchMode: "safe",
  skipRecheck: true,
  duplicateCategories: true,

  includeNonVideos: true,
  includeEpisodes: true,
  includeSingleEpisodes: true,

  outputDir: "/config",
  torrentDir: "/config/qBittorrent/BT_backup",
};
