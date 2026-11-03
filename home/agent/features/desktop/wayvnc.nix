{
  # shows labwc's output to novnc
  services.wayvnc = {
    enable = true;

    autoStart = true;

    settings = {
      address = "127.0.0.1";

      port = 5900;
    };
  };
}
