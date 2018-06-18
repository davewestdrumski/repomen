#!/bin/bash
SCRIPT=$(basename ${0})
function usage() {
  echo
  printf "SCRIPT INFORMATION:\n\n%s: Utility to run nsupdate commands against the local BIND server with checks and balances.\n\n" "${SCRIPT}"
  printf "Usage: %s [Name] [IP|Name2] [Advanced options]\n\tWhere [Name] is a fully.qualified.domain.name. and [IP] is the corresponding IPv4 address\n" "${SCRIPT}"
  printf "\tOR with --cname, where [Name2] is the underlying fully.qualified.domain.name.\n\n"
  printf "Advanced options:\n\t--force\tForce an update if the A record or PTR already exists. Do not use this unless necessary.\n"
  printf "\t--params\tJust output the paramaters being used by the script and exit\n"
  printf "\t--debug\tOutput the parameters being used by the script and then run the nsupdate in debug mode for full output.\n"
  printf "\t--cname\tCreate a CNAME instead of an A record and corresponding PTR record.\n"
  echo
  if [ "${1:-0}" -gt 0 ] ; then exit ${1} ; fi
}
function error() {
  printf "\nERROR:\n\n%s\n" "${1}"
  usage ${2}
}
fqdn=${1}
a=${2}
shift
shift
if [ -z "${fqdn}" -o -z "${a}" ] ; then
  error 'Insufficient paramters provided.' 1
fi
while [ "${#}" -gt 0 ] ; do
  case "${1}" in
    --force) force=TRUE ;;
    --params) do_params=TRUE ;;
    --debug) do_params=TRUE ; do_debug=TRUE ;;
    --cname) do_cname=TRUE ;;
    *) error "Unknown option[s] ${@}" 2 ;;
  esac
  shift
done
if [ -z "${do_cname}" ] ; then
  allowed_characters='[A-Za-z0-9-]'
else
  allowed_characters='[A-Za-z0-9_-]'
fi
good_fqdn=$(printf "%s\n" "${fqdn}" | grep -E "^(${allowed_characters}+\.){2,}\$")
if [ -z "${good_fqdn}" ] ; then
  error '[Name] must be a valid FQDN with fields constructed from characters A-Z, a-z, 0-9, or the hyphen (-).
The underscore is also allowed for CNAMEs.
It must have at least two fields separated by the "." character and the [Name] must be terminated by a final "."' 4
fi
allowed_characters='[A-Za-z0-9-]'
if [ -z "${do_cname}" ] ; then
  good_a=$(printf "%s\n" "${a}" | grep -E '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')
else
  good_a=$(printf "%s\n" "${a}"  | grep -E "^(${allowed_characters}+\.){2,}\$")
fi
if [ -z "${good_a}" ] ; then
  if [ -z "${do_cname}" ] ; then
    error '[IP] must be a valid IPv4 address composed of four octets separated by three "." characters, each octet being a number from 0 to 255.' 8
  else
    error '[Name2] must be a valid FQDN with fields constructed from characters A-Z, a-z, 0-9, or the hyphen (-).
It must have at least two fields separated by the "." character and the [Name] must be terminated by a final "."' 64
  fi
fi
# Still here, input is sane, time to derive some further variables
a_zone=$(printf "%s\n" "${fqdn}" | sed -r -e 's/^[^.]+\.//' -e 's/\.$//')
if [ -z "${do_cname}" ] ; then
  ptr_zone=$(printf "%s\n" "${a}" | awk -F. '{print $3"."$2"."$1".in-addr.arpa"}')
  ptr_record=$(printf "%s\n" "${a}" | awk -F. '{print $4"."$3"."$2"."$1".in-addr.arpa"}')
else
  ptr_zone=UNUSED
  ptr_record=UNUSED
fi
function params() {
  echo
  for param in fqdn a a_zone ptr_zone ptr_record force do_debug do_cname ; do
    printf "%s: %s\n" "${param}" "${!param:-unset}"
  done
  echo
}
# Still here, if force was supplied need to verify it is necessary and output documentation of the preexisting records.
# If force was provided even though records do not exist already, yell at user and exit angrily.
if [ -z "${do_cname}" ] ; then
  preexisting_a=$(dig "${fqdn}" | grep -o ANSWER\ SECTION)
  preexisting_a_record=$(dig +short "${fqdn}")
  no_preexisting_ptr=$(host "${a}" | grep -o NXDOMAIN)
  preexisting_ptr_record=$(host "${a}" | sed -r -e 's/^.*domain name pointer //')
else
  preexisting_a=UNUSED
  preexisting_a_record=UNUSED
  no_preexisting_ptr=UNUSED
  preexisting_ptr_record=UNUSED
  preexisting_cname=$(dig "${fqdn}" | grep -o ANSWER\ SECTION)
  preexisting_cname_record=$(dig +short "${fqdn}" | head -n1)
  target_resolution=$(dig +short "${fqdn}" | tail -n1 \
                      | grep -Eo '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')
fi
if [ -z "${do_cname}" ] ; then
  if [ -z "${no_preexisting_ptr}" ] ; then preexisting_ptr=TRUE ; fi
  if [ "${force}" == TRUE ] ; then
    if [ -n "${preexisting_a}" -o -n "${preexisting_ptr}" ] ; then # Force really was necessary here
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_a_record}" "${a}" "${preexisting_ptr_record}"
    else
      if [ -n "${do_params}" ] ; then params ; fi
      error '--force may only be supplied when records previously existed for the provided [Name] or [IP].' 16
    fi
  else
    if [ "${do_debug}" == TRUE ] ; then
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_a_record:-unset}" "${a}" "${preexisting_ptr_record:-unset}"
    fi
    if [ -n "${preexisting_a}" -o -n "${preexisting_ptr}" ] ; then # Force was not provided and there are existing records
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_a_record:-unset}" "${a}" "${preexisting_ptr_record:-unset}"
      if [ "${preexisting_a_record}" == "${a}" -a "${preexisting_ptr_record}" == "${fqdn}" ] ; then
        echo The correct records already exist - exiting without making any changes.
        if [ -n "${do_params}" ] ; then params ; fi
        exit 0
      else
        echo Records exist already and do not exactly match the provided paramaters. Exiting without making any changes.
        if [ -n "${do_params}" ] ; then params ; fi
        exit 32
      fi
    fi
  fi
  # Still here, time to construct an nsupdate against the local bind.
  if [ -z "${force}" ] ; then
    # SAFE: Either of these updates on their own will fail if that record exists already
    # and we're only getting this far in the script if neither exists already
    nsupdate_command=$(printf "%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n" \
    "server 127.0.0.1 53" \
    "zone ${a_zone}" \
    "class IN" \
    "prereq nxdomain ${fqdn}" \
    "update add ${fqdn} 1800 A ${a}" \
    "server 127.0.0.1 53" \
    "zone ${ptr_zone}" \
    "class IN" \
    "prereq nxdomain ${ptr_record}" \
    "update add ${ptr_record} 1800 PTR ${fqdn}")
  else
    # FORCE: Remove any previous record and replace it with new data
    nsupdate_command=$(printf "%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n\n" \
    "server 127.0.0.1 53" \
    "zone ${a_zone}" \
    "class IN" \
    "update delete ${fqdn} A" \
    "update add ${fqdn} 1800 A ${a}" \
    "server 127.0.0.1 53" \
    "zone ${ptr_zone}" \
    "class IN" \
    "update delete ${ptr_record} PTR" \
    "update add ${ptr_record} 1800 PTR ${fqdn}")
  fi
else # CNAME version
  if [ "${force}" == TRUE ] ; then
    if [ -n "${preexisting_cname}"  ] ; then # Force really was necessary here
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_cname_record}" "${preexisting_cname_record}" "${target_resolution}"
    else
      if [ -n "${do_params}" ] ; then params ; fi
      error '--force may only be supplied when records previously existed for the provided [Name].' 76
    fi
  else
    if [ "${do_debug}" == TRUE ] ; then
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_cname_record:-unset}" \
             "${preexisting_cname_record:-unset}" "${target_resolution:-unset}"
    fi
    if [ -n "${preexisting_cname}" ] ; then # Force was not provided and there are existing records
      printf "Preexisting record(s):\n\n%s:\t%s\n%s:\t%s\n\n" "${fqdn}" "${preexisting_cname_record:-unset}" \
             "${preexisting_cname_record:-unset}" "${target_resolution:-unset}"
      if [ "${preexisting_cname_record}" == "${a}" -a -n "${target_resolution}" ] ; then
        echo The correct records already exist - exiting without making any changes.
        if [ -n "${do_params}" ] ; then params ; fi
        exit 0
      else
        echo Records exist already and do not exactly match the provided paramaters. Exiting without making any changes.
        if [ -n "${do_params}" ] ; then params ; fi
        exit 32
      fi
    fi
  fi
  # Still here, time to construct an nsupdate against the local bind.
  if [ -z "${force}" ] ; then
    # SAFE: Either of these updates on their own will fail if that record exists already
    # and we're only getting this far in the script if neither exists already
    nsupdate_command=$(printf "%s\n%s\n%s\n%s\n%s\n\n" \
    "server 127.0.0.1 53" \
    "zone ${a_zone}" \
    "class IN" \
    "prereq nxdomain ${fqdn}" \
    "update add ${fqdn} 1800 CNAME ${a}")
  else
    # FORCE: Remove any previous record and replace it with new data
    nsupdate_command=$(printf "%s\n%s\n%s\n%s\n%s\n\n" \
    "server 127.0.0.1 53" \
    "zone ${a_zone}" \
    "class IN" \
    "update delete ${fqdn} CNAME" \
    "update add ${fqdn} 1800 CNAME ${a}")
  fi
fi
if [ "${do_debug}" == TRUE ] ; then
  params
  echo Constructed nsupdate command:
  printf "\n%s\n\n" "${nsupdate_command}"
  printf "%s\n\n" "${nsupdate_command}" | /usr/bin/nsupdate -d
else
  if [ -n "${do_params}" ] ; then
    params
    echo Constructed nsupdate command:
    printf "\n%s\n\n" "${nsupdate_command}"
    echo Exiting without making changes
    exit 0
  else
    printf "%s\n\n" "${nsupdate_command}" | /usr/bin/nsupdate
  fi
fi