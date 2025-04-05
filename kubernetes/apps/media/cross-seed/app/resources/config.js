// Torrent content layout: Original
// Default Torrent Management Mode: Automatic
// Default Save Path: /media/downloads/torrents/complete
// Incomplete Save Path: /media/downloads/torrents/incomplete

module.exports = {
  action: "inject",
  apiKey: process.env.CROSS_SEED_API_KEY,
  delay: 30,
  includeNonVideos: true,
  includeSingleEpisodes: true,
  linkCategory: "cross-seed",
  linkDirs: ["/media/downloads/torrents/complete/cross-seed"],
  linkType: "hardlink",
  matchMode: "partial",
  outputDir: null,
  port: Number(process.env.CROSS_SEED_PORT),
  qbittorrentUrl: "http://qbittorrent.media.svc.cluster.local:8080",
  skipRecheck: true,
  torznab: [], // Only using announcements from autobrr
  useClientTorrents: true,
};
