# SecHead
Security Headers Check

## How to run:

### From source
```bash
git clone https://github.com/rhovelz/SecHead && cd sechead
./sechead.sh https://www.google.com/
```

### Output
```
======================================================
> SecHead - Rhovelz ..............................
A Magic Wand to check Security Headers
======================================================
[*] Analyzing headers of https://www.google.com
[*] Effective URL: https://www.google.com
[!] Missing security header: Expect-CT
[!] Missing security header: Cross-Origin-Embedder-Policy
[!] Missing security header: Permissions-Policy
[!] Missing security header: Cross-Origin-Resource-Policy
[!] Missing security header: Referrer-Policy
[!] Missing security header: Strict-Transport-Security
[!] Missing security header: X-Content-Type-Options
[!] Missing security header: X-XSS-Protection
[!] Missing security header: X-Frame-Options
[!] Missing security header: X-Permitted-Cross-Domain-Policies
[!] Missing security header: Cross-Origin-Opener-Policy
[!] Missing security header: Content-Security-Policy
-------------------------------------------------------
[!] Headers analyzed for https://www.google.com
[+] There are 0 security headers
[-] There are not 12 security headers
```

## Disclaimer

```Not responsible for any damage caused by you!```


[![forthebadge](https://forthebadge.com/images/badges/check-it-out.svg)](https://forthebadge.com)