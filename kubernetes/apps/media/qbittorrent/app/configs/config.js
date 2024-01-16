// Torrent content layout: Original
// Default Torrent Management Mode: Automatic
// Default Save Path: /media/downloads/torrents/complete
// Incomplete Save Path: /media/downloads/torrents/incomplete

module.exports = {
  delay: 20,
  port: process.env.PORT || 2468,
  qbittorrentUrl: "http://localhost:8080",

  torznab: [
    `http://prowlarr.media.svc.cluster.local:9696/114/api?apikey=$${process.env.PROWLARR_API_KEY}`, // atr
    `http://prowlarr.media.svc.cluster.local:9696/80/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // ar
    `http://prowlarr.media.svc.cluster.local:9696/77/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // ant
    `http://prowlarr.media.svc.cluster.local:9696/16/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // blu
    `http://prowlarr.media.svc.cluster.local:9696/11/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // fl
    `http://prowlarr.media.svc.cluster.local:9696/43/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // hds
    `http://prowlarr.media.svc.cluster.local:9696/5/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // hdt
    `http://prowlarr.media.svc.cluster.local:9696/3/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // ipt
    `http://prowlarr.media.svc.cluster.local:9696/7/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // mtv
    `http://prowlarr.media.svc.cluster.local:9696/115/api?apikey=$${process.env.PROWLARR_API_KEY}`, // nbl
    `http://prowlarr.media.svc.cluster.local:9696/17/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // ptp
    `http://prowlarr.media.svc.cluster.local:9696/44/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // phd
    `http://prowlarr.media.svc.cluster.local:9696/15/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // st
    `http://prowlarr.media.svc.cluster.local:9696/78/api?apikey=$${process.env.PROWLARR_API_KEY}`,  // td
    `http://prowlarr.media.svc.cluster.local:9696/4/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // tl
    `http://prowlarr.media.svc.cluster.local:9696/6/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // ts
    `http://prowlarr.media.svc.cluster.local:9696/8/api?apikey=$${process.env.PROWLARR_API_KEY}`,   // uhdb
  ],

  apiAuth: false,
  action: "inject",
  matchMode: "safe",
  skipRecheck: true,
  duplicateCategories: true,

  includeNonVideos: true,
  includeEpisodes: true,
  includeSingleEpisodes: true,

  // I have sonarr, radarr, and manual categories set in qBittorrent
  // The save paths for them are set to the following:
  dataDirs: [
    "/media/downloads/torrents/complete/sonarr",
    "/media/downloads/torrents/complete/radarr",
    "/media/downloads/torrents/complete/manual",
  ],

  linkType: "hardlink",
  linkDir: "/media/downloads/torrents/complete/xseed",

  outputDir: "/config/xseed",
  torrentDir: "/config/qBittorrent/BT_backup",
};
