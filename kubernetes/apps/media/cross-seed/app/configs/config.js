module.exports = {
    delay: 30,

    torznab: [
        "http://prowlarr.media.svc.cluster.local:9696/11/api?apikey={{ .PROWLARR_APIKEY }}", // fl
        "http://prowlarr.media.svc.cluster.local:9696/17/api?apikey={{ .PROWLARR_APIKEY }}", // ptp
        "http://prowlarr.media.svc.cluster.local:9696/16/api?apikey={{ .PROWLARR_APIKEY }}", // blutopia
        "http://prowlarr.media.svc.cluster.local:9696/12/api?apikey={{ .PROWLARR_APIKEY }}", // hdt
        "http://prowlarr.media.svc.cluster.local:9696/15/api?apikey={{ .PROWLARR_APIKEY }}", // scenetime
        "http://prowlarr.media.svc.cluster.local:9696/14/api?apikey={{ .PROWLARR_APIKEY }}", // tl
        "http://prowlarr.media.svc.cluster.local:9696/19/api?apikey={{ .PROWLARR_APIKEY }}", // td
        "http://prowlarr.media.svc.cluster.local:9696/20/api?apikey={{ .PROWLARR_APIKEY }}", // ts
        "http://prowlarr.media.svc.cluster.local:9696/3/api?apikey={{ .PROWLARR_APIKEY }}",  // ipt
    ],

    action: "save",
    matchMode: "safe",
    includeEpisodes: true,
    includeNonVideos: true,
    torrentDir: "/config/state",
    outputDir: "/watch/cross-seed",
};