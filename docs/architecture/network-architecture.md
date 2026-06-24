# Network Architecture

## 1. AWS Region

us-west-2


## 2. Team 1 Network

Team 1 VPC: 10.101.0.0/16
  DMZ:       10.101.10.0/24
  Internal:  10.101.20.0/24
  Monitor:   10.101.30.0/24
  

## 3. Domain Naming

DNS Domain: team1.elx-lab.local
NetBIOS:    ELXLAB1

## 4. Initial MVP Topology

Student
  |
  | WireGuard VPN
  v
Team 1 VPC
  |
  +-- DMZ Subnet: 10.101.10.0/24
        |
        +-- dmz-web.team1.elx-lab.local
              - Nginx
              - Docker Compose
              - northstar-portal
              - scoring API during MVP/local test
                
                
                
## 5. Future Topology

Team 1 VPC
  |
  +-- DMZ Subnet
  |     +-- Ubuntu DMZ Web Server
  |
  +-- Internal Subnet
  |     +-- Windows Domain Controller
  |     +-- Windows Workstation
  |     +-- Linux Host
  |     +-- Internal API
  |     +-- File Share
  |
  +-- Monitor Subnet
        +-- Log forwarder / telemetry relay
        
        
## 6. Access Rules
| Source      | Destination                | Access      |
| ----------- | -------------------------- | ----------- |
| Student VPN | DMZ services               | Allow       |
| Student VPN | Internal subnet            | Deny        |
| DMZ server  | Approved internal services | Allow later |
| Instructor  | Team infrastructure        | Allow       |
| Internet    | Internal hosts             | Deny        |
