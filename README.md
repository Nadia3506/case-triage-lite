Project Summary: Case Triage Lite

Case Triage Lite is a lightweight Service Console enhancement for Salesforce Service Cloud. It improves case visibility, assignment, and monitoring using a mix of Flows, Apex, Dashboards, and LWC.

🚀 Features

Automated Case Assignment

After-Save Flow integrated with the CaseAssignmentService Apex class.

Round-robin assignment to queues or agents.

Supports Smoke Tests and full Apex Test Classes for deploy-ready coverage.

Service Level Agreement (SLA) Tracking

Custom field SLA_Minutes__c with formula mapping (High/Medium/Low → minutes).

Custom Metadata Type (CMDT) SLA_Policy__mdt for configurable SLA thresholds.

Reports to highlight SLA breaches (SLA_Minutes__c > threshold).

Reports & Dashboards

SLA Breach Cases report.

Case Assignment per Agent report.

Case Volume by Region report.

Case Triage Monitoring Dashboard with real-time charts.

Dashboard embedded directly on the Home Page.

Custom Home Page (FlexiPage)

Built with Lightning App Builder.

Includes:

My Case Triage Console (Custom LWC) – unified view of all cases assigned to the logged-in user.

Unassigned Cases – quick reassignment of incoming cases.

My Open Cases – visibility into the agent’s own workload.

Dashboards – live visualizations for SLA, assignment load, and triage status.

Custom LWC: CaseTriageConsole

Fetches cases via Apex controller (CaseTriageController).

Displays cases in a data table with Subject, Priority, Status, and Triage status.

Enables inline tracking and faster agent triage actions.

🛠 Tech Stack

Apex (CaseAssignmentService, CaseTriageController, Test Classes).

Flows (Before-Save & After-Save automation).

Lightning Web Components (LWC) (CaseTriageConsole).

Reports & Dashboards (SLA tracking, assignment distribution, triage monitoring).

FlexiPages (custom Home Page layout).

Custom Metadata Types (CMDT) (SLA policy configuration).

🎯 Business Value

Faster case assignment and SLA compliance.

Unified console for agents to triage and resolve cases quickly.

Real-time visibility for managers with dashboards.

Deploy-ready (Apex test coverage > 75%, metadata committed to GitHub).
