# DNS, Mail, Spam

## DNS records

```bash
plesk bin dns --info DOMAIN                              # show zone
plesk bin dns --add DOMAIN -a SUB -ip IP                 # A record
plesk bin dns --add DOMAIN -aaaa SUB -ip IP              # AAAA
plesk bin dns --add DOMAIN -cname SUB -canonical HOST    # CNAME
plesk bin dns --add DOMAIN -mx '' -mailexchanger HOST -priority 10
plesk bin dns --add DOMAIN -txt '' "v=spf1 mx ~all"      # TXT
plesk bin dns --add DOMAIN -srv SUB -srv-service S -srv-protocol P \
  -srv-priority N -srv-weight N -srv-port N -srv-target-host H
plesk bin dns --add DOMAIN -caa SUB -domain VAL -tag issue|issuewild|iodef
plesk bin dns --del DOMAIN -a SUB -ip IP                 # delete record
plesk bin dns --del-all DOMAIN                           # delete all
plesk bin dns --reset DOMAIN                             # restore from template
plesk bin dns --on DOMAIN / --off DOMAIN                 # enable/disable DNS
plesk bin dns --update-soa DOMAIN -soa-refresh N -soa-retry N -soa-expire N
```

## Mail

```bash
plesk bin mail --create user@domain -mailbox true -passwd "" [-mbox_quota 1G]
plesk bin mail --update user@domain [flags]
plesk bin mail --remove user@domain
plesk bin mail --list
plesk bin mail --info user@domain
plesk bin mail --on DOMAIN / --off DOMAIN
plesk bin mail --rename user@domain -new newuser@domain
```

Key flags:
```
-mailbox true|false          enable mailbox
-mbox_quota N[B|K|M|G|T]    quota
-aliases add|del:name1,name2
-forwarding true|false
-forwarding-addresses add|del:addr1,addr2
-antivirus off|inout|in|out
```

## Spam / Greylisting

```bash
plesk bin spamassassin --update user@domain -status true -hits 5.0 -action move
plesk bin spamassassin --update-server -status true
plesk bin grey_listing --update-server -status on
plesk bin grey_listing --update-domain DOMAIN -status on|off
```
