# MVP Acceptance Test Plan

## 1. Objective

Validate that the Team 1 MVP can be built, run, tested, scored, and destroyed safely.

## 2. Local Validation

| Test | Expected Result |
|---|---|
| Docker Compose config check | Pass |
| northstar-portal starts | Service reachable |
| scoring API starts | Service reachable |
| Dynamic flag generation | Unique flag created |
| Flag injection | Flag appears in seeded customer profile |
| Correct flag submission | Accepted |
| Incorrect flag submission | Rejected |
| Logs generated | App logs show access attempts |

## 3. Infrastructure Validation

| Test | Expected Result |
|---|---|
| Terraform fmt | Pass |
| Terraform validate | Pass |
| Ansible syntax check | Pass |
| GitHub deploy workflow exists | Pass |
| GitHub destroy workflow exists | Pass |


## 4. Student Path Validation  
  
Expected MVP path:  
 
1. Discover northstar-portal.  
2. Login with seeded user.  
3. Access own customer profile.  
4. Modify customer_id parameter.  
5. Access another synthetic customer profile.  
6. Retrieve dynamic flag.  
7. Submit flag to scoring API.  
8. Write finding.

## 5. Pass Criteria

The MVP is accepted when all local validation tests pass and the intended student path works from black-box conditions.  
