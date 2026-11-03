{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  # the agentbox's tsig key for its zone on de0, shared by everyone updating it (acme challenges, `tofu/dns`)
  sops.secrets."credentials/knot/tsig-secret" = {
    group = config.users.groups.dns-update.name;

    mode = "0440";
  };

  users.groups.dns-update = {};

  # `tofu/dns` takes everything but its records from here, as tofu variables
  environment.variables = {
    TF_VAR_agentbox_update_server = inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.bridge.address; # knot takes updates only from agentboxes, on their gateway

    TF_VAR_agentbox_tsig_key_name = "${config.agentbox.machine}.";

    TF_VAR_agentbox_tsig_secret_file = config.sops.secrets."credentials/knot/tsig-secret".path; # the provider takes the secret only as a value

    TF_VAR_agentbox_zone = "${config.networking.domain}.";

    TF_VAR_agentbox_edge = "${inputs.nixos-dotfiles.nixosConfigurations.de0.config.networking.fqdn}.";
  };
}
