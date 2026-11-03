# Secrets

## Files and identities

| File | Decrypted by | Holds |
| --- | --- | --- |
| `host/secrets.yaml` | the host age key, which de0 passes in as the nspawn credential `/run/host/credentials/sops.age-key` | system secrets: the TSIG and Tailscale keys, the SSH host key, the mcpproxy API key, the users' age keys, the administrator's password |
| `home/agent/secrets.yaml` | the agent's age key, `/run/secrets/users/agent/age-key` | the agent's secrets: the GitHub deploy key and the SSH key it deploys the agentbox with |
| `home/hilorioze/secrets.yaml` | the administrator's age key | the administrator's secrets |

Every file is also encrypted to the administrator's OpenPGP key, so it can be edited outside the agentbox. `.sops.yaml` sets the recipients per file; don't add or remove recipients.

## Editing

Run sops through the repository's devenv and give it the key that decrypts the file. `sops set --value-stdin` writes one value without an editor and keeps it off the command line; the value is JSON, so a string goes in quotes. The agent's own file:

```sh
<command that prints the JSON value> | SOPS_AGE_KEY_FILE=/run/secrets/users/agent/age-key direnv exec . sops set --value-stdin home/agent/secrets.yaml '["credentials"]["example"]["token"]'
```

The host file needs the host key, which only root can read; pass its contents through the environment rather than running sops as root:

```sh
<command that prints the JSON value> | SOPS_AGE_KEY="$(sudo cat /run/host/credentials/sops.age-key)" direnv exec . sops set --value-stdin host/secrets.yaml '["services"]["example"]["token"]'
```

Add new secrets freely. Replacing an existing one rotates a credential and needs permission first; the SSH host key, the deploy key and the mcpproxy API key are also registered outside this repository (de0's registry, GitHub, de0's secrets) and the age keys are the recipients in `.sops.yaml`, so replacing one of them here alone locks the agentbox out.

## Using a secret

Declare a system secret with `sops.secrets."<path>"` in the feature that uses it, and an agent secret the same way in a feature under `home/agent/features/`. Hand the consumer the declaration's `.path`; sops-nix decrypts the file at activation, so the value never enters the Nix store. Set `owner`, `group` or `mode` when a service other than root reads it, and `restartUnits` when it should restart after the secret changes.

Never read a secret during evaluation (`builtins.readFile`, string interpolation of its contents), pass it on a command line, or print it to check that it works.
