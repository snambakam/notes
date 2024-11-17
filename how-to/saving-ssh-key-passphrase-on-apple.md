# Saving SSH Key Passphrase on Mac

## Store the passphrase in the keychain

```
ssh-add --apple-use-keychain ~/.ssh/[your-private-key]
```

```

## Configure SSH-agent to use the keychain

```
Host *
    UseKeychain yes
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_rsa
```
