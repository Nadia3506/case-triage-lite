public with sharing class CaseTriageController {

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {
        return [
            SELECT Id, CaseNumber, Subject, Priority, Status, Triage_Status__c
            FROM Case
            WHERE OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
    }

    @AuraEnabled
    public static void updateCase(Case c) {
        update c;
    }
}