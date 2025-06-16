# Internal Application Provisioning through a Reverse Proxy Network

This project streamlines the process for developers and interns to host applications on a MIE Proxmox cluster, making them viewable to others through a public domain. The full proposal can be viewed here: [[Proposal](https://docs.google.com/document/d/1EHcHZj-bI2f1qwtq_KuGsq3fQs4_8lY5Ame7zjVVK0o/edit?tab=t.0#heading=h.dsf26zek2d4x)].

---

### General Architecture Overview

![Proxmox Architecture Diagram](https://github.com/user-attachments/assets/7df7d871-dc2d-4165-8573-37dab33ba60d)


### Project Structure

```
|-- Container\ Provisioning
|   |-- create_container.sh
|   |-- hostnameRunner.js
|   |-- hostnames.js
|   `-- manageHostnames.js
|-- README.md
|-- dnsmasq
|   |-- dnsmasq.conf
|   `-- leases
|       |-- Beta-leases.conf
|       |-- PR-leases.conf
|       |-- README
|       `-- Stable-leases.conf
|-- iptables
|   |-- dnsmasq-iprules.v4
|   `-- proxmox-host-iprules.v4
|-- nginx\ r-proxy
|   |-- nginx.conf
|   `-- wildcard_proxy.conf
|-- ssh
|   |-- directSSH.sh
|   `-- general_sshd_config
`-- vscode-ssh-config-template

```

This repository includes scripts and configuration files for LXC container provisioning, dnsmasq (DNS/DHCP), SSH, and an Nginx reverse proxy.

-   `Container Provisioning/create_container.sh`: The primary script that communicates with the Proxmox `pct` CLI to provision new containers based on user preferences.

-   `Container Provisioning/hostnameRunner.js`: A JavaScript runner file that imports functions from `manageHostnames.js`, making them usable in `create_container.sh` by specifying the Node.js runtime, runner file, function names, and arguments.

-   `Container Provisioning/manageHostnames.js`: A CommonJS module that exports functions to interact with a JSON file, preventing duplicate application (container) names within the cluster.

-   `dnsmasq/dnsmasq.conf`: The main dnsmasq configuration file, responsible for managing three unique internal Class B subnets (10.8.0.0/16, 10.14.0.0/16, 10.22.0.0/16).

-   `dnsmasq/leases/*`: Individual lease files for each subnet (container type). These files specify the `dhcp-range`, lease time, and a list of current leases. Note: `Stable-leases.conf` contains static lease mappings.

-   `iptables/dnsmasq-iprules.v4`: IP routing rules for the dnsmasq server, used to forward traffic between internal VLAN subnets to an Ethernet-based interface that communicates with the Proxmox host and an external gateway.

-   `iptables/proxmox-host-iprules.v4`: IP routing rules for the Proxmox host that forward HTTP traffic to the Nginx reverse proxy.

-   `nginx r-proxy/nginx.conf`: The standard, out-of-the-box configuration file for Nginx (Default HTTP configurations).

-   `nginx r-proxy/wildcard_proxy.conf`: The core Nginx logic that uses a wildcard domain and the dnsmasq resolver to translate internal subdomains to IP addresses and return the content to the client.

-   `ssh/directSSH.sh`: [Experimental] A non-production script intended to replace jump host functionality by explicitly prompting the user for an application name. It does not work well with IDE-based SSH clients and extensions, such as Remote-SSH in VSCode.

-   `ssh/general_sshd_config`: SSH configuration for jump hosts that ensures user SSH sessions are not interactive in the shell but can still forward SSH traffic.

-   `vscode-ssh-config-template`: A sample configuration file for connecting to a container project in VSCode using the Remote-SSH extension.


### How It Works

Containers are categorized into three types based on their lease: **PR**, **Beta**, and **Stable**. The primary difference is the DHCP lease time.

| Lease Type | Internal IP Range | Lease Time |
| :--- | :--- | :--- |
| **PR** | `10.8.0.0/16` | 48 hours |
| **Beta** | `10.14.0.0/16` | 168 hours |
| **Stable** | `10.22.0.0/16` | Infinite |

**Dnsmasq**: Manages all internal domains and subnets, allocating IP addresses in the correct range depending on the VLAN and Bridge. It communicates with the Nginx proxy to resolve internal hostnames to IP addresses and stores both dynamic and static leases.

**Nginx Reverse Proxy**: All incoming traffic is forwarded to the Nginx server. The server extracts the internal application name from the request, communicates with dnsmasq to resolve its IP address via a `proxy_pass`, and returns the application's content to the client.

**Container Provisioning**: A collection of Shell and JavaScript scripts that allow users to provision their own containers (applications). Users must provide a container name, password, lease type, and an optional public SSH key (highly recommended).

**Jump Hosts**: This setup consists of the Proxmox host and an internal SSH jump host. The Proxmox host cannot directly SSH into the internal VLANs, but the SSH jump host can. Therefore, SSH traffic "jumps" through these two hosts to reach the designated container.

**Note**: In this LAN, all containers have a public-facing domain in the format of `[appname].mie.local`. This will eventually change to `[appname].opensource.mieweb.com`.

### Usage

1.  Clone this repository to your Proxmox host.
2.  Set up at least three additional VLANs and Bridges on the host machine.
    -   **Note**: You may need to troubleshoot the network setup. My setup uses an external gateway with a Wi-Fi adapter. In a production environment, the host itself would have the public-facing IP, and each service would have either a public or private IP.
3.  Place the configuration files in their correct locations. Create separate containers for the Nginx reverse proxy, the dnsmasq server, and the SSH jump host. Update and apply all service configurations.
4.  Run `Container Provisioning/create_container.sh` on your Proxmox machine to provision new containers.
