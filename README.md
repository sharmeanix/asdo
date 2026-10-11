# asdo

**asdo** is a simple script to leverage the power of FreeBSD's mdo(1) with the added benefit of authentication.

## Security considerations

The script itself does NOT need any special privileges, su(1) manages authentication and mac_do(4) handles authorization.

This is a hobby project and may not be a fit for your threat model.

Use at your own risk.

## Why

I prefer using system's built-in features over extensions.

## How

asdo is just a script wrapping around an idea to put mdo(1)'s privileges behind authentication.

The concept works by writing a mac_do(4) rule to grant a `_do` account the privileges you desire, then asdo invokes su(1) to authenticate you and execute your commands.

All authentication is done by su(1).

## Setup

First make sure you're running FreeBSD 15.0 or a later version, then familiarize yourself with mac_do(4) and mdo(1).

When you feel confident enough, continue reading.

1. Create a new user with your desired username suffixed by _do (asdo assumes this user's username to be either your username or the name of any groups you're a member of by default).

2. Set a password for the new user, you'll use this password with asdo.

3. Write mac_do(4) rules for the new user.

4. TEST THAT THE SETUP WORKS AS EXPECTED WITH MDO(1) AND ASDO(1).

5. Make the rules permanent by appending them to `/etc/sysctl.conf`.

## Installation

Download the script and run the following as root:
```sh
install -o 0 -g 0 -m 555 /path/to/script /usr/local/bin/asdo
```

### Replace /path/to/script with the path to the script.

To install the man page as well:
```sh
gzip /path/to/asdo.1
install -o 0 -g 0 -m 644 /path/to/asdo.1.gz /usr/local/share/man/man1
```

### Replace /path/to/asdo.1 with the appropriate path.

## Usage

```sh
asdo [-e] [-s] [-u user] [-a user/group] command [args]
```

## Options

- `-e`

Preserves your environment variables and CWD.

- `-s`

Simulates a fresh login and discards your environment variables and CWD.

`-e` and `-s` are mutually exclusive, the last one is used.

Default behaviour discards your environment variables and creates a minimal set and keeps your CWD intact.

- `-u user`

Will try to execute as _user_, defaults to root.

- `-a user/group`

Will try to authenticate against _user/group_ suffixed by _do, by default, your username is tried first, then every group you're a member of.

## License

[BSD-3-Clause](LICENSE)
