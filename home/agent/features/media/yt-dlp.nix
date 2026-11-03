{osConfig, ...}: {
  programs.yt-dlp = {
    enable = true;

    settings.proxy = builtins.head osConfig.agentbox.proxies; # youtube asks de0's datacenter address to sign in; yt-dlp takes a single proxy, without chromium's fallback to the next one
  };
}
