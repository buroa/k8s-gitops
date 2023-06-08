module.exports = {
  delay: 30,

  torznab: [
    "http://prowlarr.media.svc.cluster.local:9696/3/api?apikey={{ .PROWLARR_APIKEY }}", // ipt
    "http://prowlarr.media.svc.cluster.local:9696/4/api?apikey={{ .PROWLARR_APIKEY }}", // tl
    "http://prowlarr.media.svc.cluster.local:9696/5/api?apikey={{ .PROWLARR_APIKEY }}", // hdt
    "http://prowlarr.media.svc.cluster.local:9696/6/api?apikey={{ .PROWLARR_APIKEY }}", // ts
    "http://prowlarr.media.svc.cluster.local:9696/7/api?apikey={{ .PROWLARR_APIKEY }}", // mtv
    "http://prowlarr.media.svc.cluster.local:9696/11/api?apikey={{ .PROWLARR_APIKEY }}", // fl
    "http://prowlarr.media.svc.cluster.local:9696/15/api?apikey={{ .PROWLARR_APIKEY }}", // st
    "http://prowlarr.media.svc.cluster.local:9696/16/api?apikey={{ .PROWLARR_APIKEY }}", // blu
    "http://prowlarr.media.svc.cluster.local:9696/17/api?apikey={{ .PROWLARR_APIKEY }}", // ptp
    "http://prowlarr.media.svc.cluster.local:9696/21/api?apikey={{ .PROWLARR_APIKEY }}", // hdb
  ],

  action: "inject",
  matchMode: "safe",
  skipRecheck: true,
  includeEpisodes: true,
  includeNonVideos: true,
  duplicateCategories: true,
  outputDir: "/cross-seeds",
  torrentDir: "/config/qBittorrent/BT_backup",
  qbittorrentUrl: "http://qbittorrent.media.svc.cluster.local:8080",
  rssCadence: "15 minutes", // autobrr doesnt get every announcement
};
