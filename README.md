# Case Triage Lite 🚀

## 📌 Project Summary
This project showcases my Salesforce Developer skills by implementing a **Case Triage and Assignment System**.  
It demonstrates how to combine **Flows**, **Apex**, and **Queues** to handle real-world Service Cloud scenarios.  

### Key Features:
- **Custom Fields & Objects**
  - `Region__c`, `Triage_Status__c`, `SLA_Minutes__c`, and `Case_Score__c` on `Case`
  - `Triage_Log__c` custom object to track assignments  

- **Flows**
  - **Before-Save Flow** → Ensures cases without an owner default to the *Support – Tier 1* queue  
  - **After-Save Flow** → Calls Apex to assign cases round-robin to available agents and logs assignments  

- **Apex**
  - `CaseAssignmentService` class handles round-robin assignment logic  
  - Includes **unit tests** and a **smoke test** to guarantee >75% code coverage and deploy-readiness  

### Why This Project?
- Simulates a **real customer support scenario** (case routing + SLA tracking).  
- Shows my skills in:
  - Declarative automation (Flow)  
  - Programmatic development (Apex)  
  - Testing strategies (unit vs. smoke tests)  
  - Git & version control  

---

## 🛠️ Tech Stack
- Salesforce Developer Org
- Apex
- Flows (Before-Save & After-Save)
- GitHub for version control
- VS Code + Salesforce CLI

