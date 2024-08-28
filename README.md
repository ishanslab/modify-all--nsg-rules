# modify-all-nsg-rules  

- This script will check all NSG rules in the given subscription.
- If any NSG rule contains source as *, 0.0.0.0/0 or Internet, and destination ports are *, 22 or 3389.
- Then it will change the access of that NSG rule to deny. 
