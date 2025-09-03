public with sharing class CaseTriageController {

    // Return cases owned by the passed userId.
    // If includeQueue=true, also include Support_Tier_1 queue cases.
    @AuraEnabled(cacheable=true)
    public static List<Case> getCases(Id ownerId, Boolean includeQueue) {
        Id effectiveUserId = (ownerId == null) ? UserInfo.getUserId() : ownerId;

        Set<Id> ownerIds = new Set<Id>{ effectiveUserId };

        if (includeQueue == true) {
            List<Group> qs = [
                SELECT Id
                FROM Group
                WHERE Type = 'Queue' AND DeveloperName = 'Support_Tier_1'
                LIMIT 1
            ];
            if (!qs.isEmpty()) ownerIds.add(qs[0].Id);
        }

        return [
            SELECT Id, CaseNumber, Subject, Priority, Status, Triage_Status__c, OwnerId
            FROM Case
            WHERE OwnerId IN :ownerIds
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void updateCase(Case c) {
        update c;
    }
}