#!/usr/bin/env sh

help() {

    printf 'iptables-dns-chain - Create or update an iptables chain from DNS names\n\n'

    printf 'Usage: iptables-dns-chain [-t table] -c chain domain1.example.com [domain2.example.com ...]\n\n'

    printf 'Options:\n'
    printf -- '-h  this help text\n'
    printf -- '-c  iptables chain\n'
    printf -- '-t  iptables table\n'

    exit 0

}

chain_ips() {
    /sbin/iptables -t "$table" -S "$chain" 2>/dev/null | tail -n+2 | cut -d' ' -f4 | cut -d/ -f1
}

ip_in_list() {
    for ip in $ips
    do
        if [ "$1" = "$ip" ]
        then
            return 0
        fi
    done
    return 1
}

while getopts ":hc:t:" opt
do
    case "$opt" in
        h)
            help
            ;;
        c)
            chain=$OPTARG
            ;;
        t)
            table=$OPTARG
            ;;
        \?)
            printf 'Unrecognized option: -%s\n' "$OPTARG" 1>&2
            exit 1
            ;;
        :)
            printf -- '-%s requires an argument\n' "$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

[ $# -eq 0 ] && help
[ -z "$chain" ] && help
[ -z "$table" ] && table='filter'

iptables -t "$table" -N "$chain" 2>/dev/null

ips=''

for dns in "$@"
do
    for ip in $(getent ahostsv4 "$dns" | awk '{print $1}' | uniq)
    do
        rule_count=1
        found=0
        for chain_ip in $(chain_ips)
        do
            if [ "$chain_ip" = "$ip" ]
            then
                /sbin/iptables -t "$table" -R "$chain" "$rule_count" -s "$ip" -j ACCEPT -m comment --comment "$dns"
                found=1
                break
            fi
            rule_count=$((rule_count+1))
        done
        if [ "$found" -eq 0 ]
        then
            /sbin/iptables -t "$table" -A "$chain" -s "$ip" -j ACCEPT -m comment --comment "$dns"
        fi
        ips="$ip $ips"
    done
done

rule_count=1
for chain_ip in $(chain_ips)
do
    if ip_in_list "$chain_ip"
    then
        rule_count=$((rule_count+1))
    else
        eval "/sbin/iptables -t $table -D $chain $rule_count"
    fi
done
