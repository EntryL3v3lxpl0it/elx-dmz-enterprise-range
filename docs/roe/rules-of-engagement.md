# Rules of Engagement

## 1. Purpose

This document defines authorized student activity for the ELX DMZ-to-Enterprise Offensive Security Training Range.

## 2. In-Scope

For MVP testing, the following are in scope:

team1.elx-lab.local
DMZ subnet: 10.101.10.0/24
northstar-portal
scoring API
student-provided VPN access path

## 3. Out-of-Scope

The following are out of scope:

- Public internet targets.
- ELX production systems.
- Other students' environments.
- AWS metadata or cloud control plane attacks unless explicitly assigned.
- Denial-of-service testing.
- Malware deployment.
- Persistence outside the assigned lab path.
- Credential reuse outside the lab.
- Destructive actions.

## 4. Allowed Activities

Students may:

- Enumerate assigned hosts and services.
- Intercept and replay HTTP requests.
- Test authentication and authorization behavior.
- Validate the assigned vulnerability classes.
- Capture dynamic flags.
- Collect minimal evidence.
- Submit a formal PDF report.

## 5. Evidence Rules

Students shall collect only the minimum evidence necessary to prove impact.

Acceptable evidence includes:

- Commands and output.
- HTTP requests and responses.
- Screenshots.
- Logs.
- Flag values.
- Timeline notes.

## 6. Reporting

Students shall submit:

- Captured flags through the scoring portal.
- Final report in PDF format.
- Evidence appendix where required.

## 7. Safety

All testing must remain within assigned scope. If a student discovers unintended access, they must stop, document the observation, and notify the instructor.  
