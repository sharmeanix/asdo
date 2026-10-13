#!/bin/sh

#  Copyright (c) 2026 Armin Shirazi
#
#  SPDX-License-Identifier: BSD-3-Clause

# 1. Add a new user with the suffix of _do and set a password for it.
# 2. Add a new mac_do(4) rule for that user to allow mdo(1) usage.
# 3. Be creative ;-)

# Default behaviour preserves cwd but discards the environment
# and adds a minimal set. -e preserves everything, -s simulates
# a fresh login, doesn't preserve cwd or env.
#
# -u specifies the user to run the command as, -a specifies the
# user to authenticate against, default is $USER_do, if not available,
# tests every group you're a member of.
#
# Your shell's stdin IS NOT inherited by the final command.
#
# xargs discards the utility's exit code and returns 1 on error, which
# leads to the inability of determining what your command actually returned,
# thus upon any errors 1 will be returned.

err () {
echo "$@" 1>&2
exit 1
}

auth () {
[ "$1" -le 0 ] && return 1
env "$envopt" $env_user su -m "$auth_user" <<EOF
mdo -u "$user" -g "$group" su "$suopt" "$user" -c '
	printf %s "$args" | base64 -d |
		xargs -0o env "$envopt2" $env_user2 "$userenv" "$termenv" command' ||
			return 3
EOF
retval=$?
[ $retval -eq 0 ] || auth $(($1 - $retval))
}

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin"
user="root"
envopt="-iL"
envopt2="--"
suopt="--"

unset auth_user
unset env_user
unset env_user2

while getopts esu:a: flag; do
	case "$flag" in
	"e")
		envopt="--"
		suopt="-m" ;;
	"s")
		envopt="-iL"
		suopt="-l" ;;
	"u")
		user=$(id -un "$OPTARG") || exit 1 ;;
	"a")
		auth_user=$(id -un "${OPTARG}_do" 2>/dev/null) ||
			err "You are not allowed to authenticate through $OPTARG" ;;
	"?")
		OPTIND="$(($# + 1))"
		break ;;
	esac
done
shift $(($OPTIND - 1))

[ "$#" -eq 0 ] && err "usage: asdo [-e] [-s] [-u user] [-a user/group] <command> [args]"

if [ -z "$auth_user" ]; then
	if ! auth_user=$(id -un "$(id -un)_do" 2>/dev/null); then
		for name in $(id -Gn); do
			auth_user=$(id -un "${name}_do" 2>/dev/null) && break
			unset auth_user
		done
		[ -z "$auth_user" ] && err "You are not allowed to authenticate!"
	fi
fi

termenv="_asdo_placeholder_="
userenv="_asdo_placeholder_="

if [ "$envopt" != "--" ]; then env_user="$user";
	[ "$suopt" != "-l" ] && env_user2="$user" && envopt2="-U"
	[ ! -z "$TERM" ] && infocmp >/dev/null 2>&1 && termenv="TERM=$TERM"
fi

[ ! -z "$env_user" ] && userenv="USER=$env_user"

group=$(id -gn "$user") || exit 1

args=$(printf '%s\0' "$@" | base64) || exit 1

auth 3
