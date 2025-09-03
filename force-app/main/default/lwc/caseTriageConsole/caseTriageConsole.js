import { LightningElement, wire, track } from 'lwc';
import getCases from '@salesforce/apex/CaseTriageController.getCases';
import USER_ID from '@salesforce/user/Id';

const COLUMNS = [
  { label: 'Case #', fieldName: 'CaseNumber', initialWidth: 120 },
  { label: 'Subject', fieldName: 'Subject' },
  { label: 'Priority', fieldName: 'Priority', initialWidth: 110 },
  { label: 'Status', fieldName: 'Status', initialWidth: 130 },
  { label: 'Triage', fieldName: 'Triage_Status__c', initialWidth: 140 }
];

export default class CaseTriageConsole extends LightningElement {
  columns = COLUMNS;
  @track cases = [];
  @track error;

  // includeQueue = true shows both "my cases" and Support_Tier_1 queue cases
  @wire(getCases, { ownerId: USER_ID, includeQueue: true })
  wired({ data, error }) {
    if (data) {
      this.cases = data;
      this.error = undefined;
    } else if (error) {
      // Surface in console so you can see the exact issue if something fails (FLS, bad field, etc.)
      // eslint-disable-next-line no-console
      console.error('getCases error', JSON.stringify(error));
      this.error = error;
      this.cases = [];
    }
  }
}


