// https://github.com/cross-seed/cross-seed

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
module.exports = {

    delay: 15,

    torznab: [
        "http://prowlarr.media.svc.cluster.local:9696/11/api?apikey={{ .PROWLARR_APIKEY }}", // fl
        "http://prowlarr.media.svc.cluster.local:9696/17/api?apikey={{ .PROWLARR_APIKEY }}", // ptp
        "http://prowlarr.media.svc.cluster.local:9696/16/api?apikey={{ .PROWLARR_APIKEY }}", // blutopia
        "http://prowlarr.media.svc.cluster.local:9696/12/api?apikey={{ .PROWLARR_APIKEY }}", // hdt
        "http://prowlarr.media.svc.cluster.local:9696/15/api?apikey={{ .PROWLARR_APIKEY }}", // scenetime
        "http://prowlarr.media.svc.cluster.local:9696/14/api?apikey={{ .PROWLARR_APIKEY }}", // tl
        "http://prowlarr.media.svc.cluster.local:9696/3/api?apikey={{ .PROWLARR_APIKEY }}",  // ipt
    ],

    matchMode: "safe",
    torrentDir: "/config/state",
    outputDir: "/watch/cross-seed",
    includeEpisodes: true,
    includeNonVideos: true,
    action: "save",
    rssCadence: "15 minutes",
    searchCadence: "1 week",
    excludeRecentSearch: "1 week",

};
