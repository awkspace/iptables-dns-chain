## iptables DNS chain script

A shell script to create/update DNS rules in an iptables chain. Call it from
cron!

**Warning:** To keep the state of the specified chain consistent, the rest of
the rules will be wiped. Maybe don't use it on INPUT.

### Usage

```
iptables-dns-chain - Create or update an iptables chain from DNS names

Usage: iptables-dns-chain [-t table] -c chain domain1.example.com [domain2.example.com ...]

Options:
-h  this help text
-c  iptables chain
-t  iptables table
```
