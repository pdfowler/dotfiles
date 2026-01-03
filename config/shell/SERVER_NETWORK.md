# Server Network Configuration

## Server Information

- **Hostname**: `dean`
- **IP Address**: `192.168.13.105`
- **Network**: Local (192.168.13.0/24)
- **Domain**: `pdfowler.net` (UniFi configuration in progress)
- **Service**: Screen Sharing (VNC) on port 5900

## Quick Diagnostics

Run network diagnostics:
```bash
check-dean
# or
network-check dean 192.168.13.105
```

## Common Issues & Solutions

### Intermittent Connectivity

**Symptoms**: Screen sharing works sometimes but not always

**Possible Causes**:
1. **DNS Resolution Issues** (most likely during UniFi cert migration)
   - Hostname may not resolve consistently
   - Certificate validation failures
   - DNS cache issues

2. **Network Configuration Changes**
   - UniFi domain/cert changes affecting DNS
   - DHCP lease renewals
   - Network switch port issues

3. **Mac Server Issues**
   - Sleep/wake cycles
   - Network interface power management
   - Screen Sharing service restarting

**Solutions**:

1. **Use IP address directly** (bypasses DNS):
   ```bash
   open vnc://192.168.13.105
   ```

2. **Flush DNS cache** (on client Mac):
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```

3. **Check Screen Sharing service** (on server Mac):
   - System Settings → General → Sharing
   - Ensure "Screen Sharing" is enabled
   - Check "Allow access for" settings

4. **Check network interface**:
   ```bash
   # On server (dean)
   ifconfig | grep -A 5 "inet 192.168.13"
   ```

5. **Test connectivity**:
   ```bash
   # Ping test
   ping -c 5 192.168.13.105
   
   # Port test
   nc -zv 192.168.13.105 5900
   ```

### DNS/Certificate Issues (UniFi Migration)

During the transition to `pdfowler.net` domain with signed certificates:

1. **Hostname may not resolve**:
   - Use IP address: `192.168.13.105`
   - Or add to `/etc/hosts`:
     ```
     192.168.13.105  dean
     192.168.13.105  dean.pdfowler.net
     ```

2. **Certificate validation failures**:
   - Screen Sharing may show certificate warnings
   - Accept/trust the certificate when prompted
   - Or disable certificate validation temporarily

3. **UniFi Controller Settings**:
   - Check DNS settings in UniFi Controller
   - Verify DHCP is assigning correct DNS servers
   - Check if custom DNS entries are needed

### Network Path Issues

If connectivity is completely lost:

1. **Physical checks**:
   - Network cable connections
   - Switch port status (check UniFi controller)
   - Power to network equipment

2. **ARP table**:
   ```bash
   arp -n 192.168.13.105
   ```
   - If "incomplete", there's a layer 2 issue

3. **Traceroute**:
   ```bash
   traceroute 192.168.13.105
   ```
   - Shows where packets are being dropped

## Screen Sharing Connection

### Via IP (most reliable during DNS issues):
```bash
open vnc://192.168.13.105
```

### Via Hostname:
```bash
open vnc://dean
# or
open vnc://dean.pdfowler.net
```

### Manual Connection:
1. Open Finder
2. Cmd+K (Connect to Server)
3. Enter: `vnc://192.168.13.105` or `vnc://dean`

## Monitoring & Logs

### Check Screen Sharing logs (on server):
```bash
# System logs
log show --predicate 'process == "ScreenSharingAgent"' --last 1h

# Or check Console.app for ScreenSharingAgent
```

### Network interface status:
```bash
# On server
networksetup -listallhardwareports
ifconfig en0  # or en1, depending on interface
```

### UniFi Controller:
- Check device status for "dean"
- Review network events/logs
- Verify DHCP lease for 192.168.13.105

## Prevention

1. **Static IP Assignment**:
   - Configure static IP in UniFi for dean
   - Or set static IP on Mac: System Settings → Network → Configure IPv4 → Manually

2. **Wake on Network**:
   - Ensure Mac doesn't sleep network interfaces
   - System Settings → Energy Saver → Prevent automatic sleeping

3. **mDNS/Bonjour**:
   - Ensure mDNSResponder is running
   - Check: `ps aux | grep mDNSResponder`

4. **Firewall Rules**:
   - Ensure port 5900 is open
   - Check: System Settings → Network → Firewall

## Related Files

- Network diagnostics script: `config/shell/network-diagnostics.sh`
- Aliases: `config/shell/aliases.sh` (see `check-dean`, `network-check`)


