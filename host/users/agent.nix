{config, ...}: {
  sops.secrets."users/agent/age-key".owner = config.users.users.agent.name;

  users.users = {
    deployer.openssh.authorizedKeys.keys = ["CHANGEME"]; # the agent's `credentials/ssh/private-key`, which deploys the agentbox from itself

    agent = {
      isNormalUser = true;

      linger = true; # keeps the agent's systemd manager running, whose `sops-nix` service decrypts the home secrets after every switch rather than at the next login

      openssh.authorizedKeys.keys = ["CHANGEME"];

      extraGroups = [config.users.groups.dns-update.name]; # `tofu/dns` signs its updates with the agentbox's tsig key
    };
  };

  security.sudo.extraRules = [
    {
      users = [config.users.users.agent.name];

      commands = [
        {
          command = "ALL";

          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  home-manager.users.agent.imports = [../../home/agent];
}
