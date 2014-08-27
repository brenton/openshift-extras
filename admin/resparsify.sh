#!/bin/bash
# This script is a workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1122271

set -e

OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
backup_dir="/var/lib/openshift"
fix=false
usage="$(basename "$0") [-h] [-b backup directory] [-u uuid] [-f] -- Recreate sparse files for gears.

By default $(basename "$0") will search for gears exceeding quote and print
them to the console.  To attempt the 'resparsification' process choose either
the -u or -f options.

NOTE: A tarball of the original gear contents will be backed up.  Please ensure
that there is sufficient storage available.  If the gear is running it will be
first stopped and then later restored after the process is complete.

-h Help
-b set the directory for backups.  Default: ${backup_dir}
-u fix a specific gear uuid
-f fix problems
"

fix_gear()
{
  uuid=$1
  backup_dir=$2
  echo Fixing $uuid
  quota -v $uuid || true
  STATE=$( cat /var/lib/openshift/$uuid/app-root/runtime/.state )
  if [ "$STATE" = "started" ]; then
    echo Stopping $uuid
    oo-admin-ctl-gears stopgear $uuid
  fi
  rsync -axS /var/lib/openshift/$uuid/. /var/lib/openshift/s$uuid
  tar -C /var/lib/openshift -cpzf ${backup_dir}/$uuid-nonsparse.tgz $uuid
  rm -rf /var/lib/openshift/$uuid/
  mv /var/lib/openshift/s$uuid /var/lib/openshift/$uuid
  oo-restorecon $uuid
  quota -v $uuid
  if [ "$STATE" = "started" ]; then
    echo Starting $uuid
    oo-admin-ctl-gears startgear $uuid
  fi
}

while getopts "h?b:u:f" opt; do
    case "$opt" in
    h|\?)
        echo "$usage"
        exit 0
        ;;
    b)  backup_dir="${OPTARG%/}"
        ;;
    u)  uuid=${OPTARG}
        ;;
    f)  fix=true
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [[ -z "$uuid" ]]; then
  echo Searching for gears exceeding quota...
  for uuid in $( repquota -a | grep '+-' | awk '{ print $1 }' ); do
    if [ -d "/var/lib/openshift/$uuid/" ]; then
      if $fix; then  
        fix_gear $uuid $backup_dir
      else 
        echo $uuid is exceeding quota.  See -h for options to attempt resparsification.
      fi
    else
      echo $uuid is exceeding quote but is not an OpenShift gear.
    fi
  done
else
  fix_gear $uuid $backup_dir
fi

echo Done.
