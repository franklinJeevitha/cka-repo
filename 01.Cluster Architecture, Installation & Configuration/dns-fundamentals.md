
# 🌐 DNS & Name Resolution Fundamentals

DNS (Domain Name System) is the "Phonebook of the Internet." It maps hostnames to IP addresses so we don't have to memorize numbers like `142.250.190.46`.

## 1. The Local Phonebook: `/etc/hosts`
Before the internet had centralized DNS servers, every computer had a static text file to map names to IPs.
* **File Path:** `/etc/hosts`
* **Format:** `[IP Address] [Hostname] [Alias]`
* **Example:** `127.0.0.1 localhost`
* **Limitation:** It doesn't scale. You can't manually add every website on the internet to this file.

---

## 2. The Decision Maker: `nsswitch.conf`
When you type `ping my-server`, how does Linux know whether to check the `/etc/hosts` file first or ask a DNS server?
* **File Path:** `/etc/nsswitch.conf`
* **The "hosts" line:** Look for `hosts: files dns`.
    * **files:** Check `/etc/hosts` first.
    * **dns:** If not found in the file, ask the DNS server.

---

## 3. The DNS Client Config: `resolv.conf`
If `nsswitch` points to "dns," the system looks here to find out **which** DNS server to talk to.
* **File Path:** `/etc/resolv.conf`
* **Key Entries:**
    * `nameserver`: The IP of the DNS server (e.g., `8.8.8.8` for Google).
    * `search`: A list of domains to append automatically. If you have `search prod.svc.cluster.local` and you ping `web`, it will automatically try `web.prod.svc.cluster.local`.

---

## 4. The Domain Tree Structure (The Google Example)
DNS is hierarchical, shaped like an inverted tree.



* **Root (.)**: The very top of the tree (usually invisible).
* **TLD (Top-Level Domain)**: `.com`, `.org`, `.in`.
* **Domain**: `google.com`.
* **Subdomain**: `mail.google.com` or `drive.google.com`.
* **Deep Subdomain**: `internal.dev.mail.google.com`.

---

## 5. DNS Record Types
The DNS server doesn't just store IPs; it stores different types of information:

| Type | Purpose | Example |
| :--- | :--- | :--- |
| **A** | Maps a name to an **IPv4** address. | `google.com -> 1.2.3.4` |
| **AAAA** | Maps a name to an **IPv6** address. | `google.com -> 2001:db8::1` |
| **CNAME** | An **Alias** (Maps one name to another name). | `web -> app.prod.svc` |
| **MX** | Mail Exchange (Where to send emails). | `google.com -> smtp.google.com` |
| **TXT** | Text notes (Used for security/verification). | `v=spf1 include:_spf.google.com` |

---

## 6. The Tools of the Trade (Troubleshooting)
When a pod can't reach a service, use these tools to see what the DNS server is thinking.

### **A. nslookup** (Simple)
Great for a quick check to see if a name resolves.
```bash
nslookup google.com
```

### **B. dig** (The Pro Tool)
Provides detailed information about the DNS query, including how long it took and which server answered.
```bash
# Query the 'A' record for a domain
dig google.com

# Query a specific DNS server (e.g., ask Google's DNS directly)
dig @8.8.8.8 google.com

# Short output (IP only)
dig google.com +short
```



---

## 💡 Practical Engineering Tips

* **The "Dot" at the end:** In technical DNS configurations, a fully qualified name ends in a dot (e.g., `google.com.`). This tells the system "don't look at the search path, this is the absolute end of the tree."
* **Caching:** Most modern Linux systems use a local cache (like `systemd-resolved`). If you change a DNS record and don't see the update, you might need to flush your local cache.
* **Kubernetes Connection:** Inside a K8s cluster, **CoreDNS** acts as the nameserver. Every pod's `/etc/resolv.conf` is automatically configured by the Kubelet to point to the CoreDNS Service IP.

---
