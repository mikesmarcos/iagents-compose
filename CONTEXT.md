# Home Lab Orchestration

This context defines the language used to operate applications hosted in the private home-lab environment.

## Language

**Lab Service**:
An application capability hosted by the lab and private by default, available only inside the trusted local and remote-access environment unless explicitly designated public.
_Avoid_: Public service, internet-facing service

**Lab Hostname**:
A stable name in the lab namespace that identifies an entry point to a Lab Service without implying public accessibility.
_Avoid_: Public hostname, service URL

**Trusted Access Environment**:
The boundary containing the lab host, hosted workloads, and explicitly authorized remote clients from which private Lab Services may be accessed.
_Avoid_: Public internet, trusted network
