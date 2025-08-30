@IsTest
private class CaseAssignmentServiceSmokeTest {

    // Ensure queue exists, can own Case, and includes the running user (SETUP DML)
    private static Id ensureQueueWithMe() {
        List<Group> qs = [SELECT Id FROM Group WHERE DeveloperName='Support_Tier_1' AND Type='Queue' LIMIT 1];
        Group q = qs.isEmpty()
            ? new Group(Name='Support - Tier 1', DeveloperName='Support_Tier_1', Type='Queue')
            : qs[0];
        if (qs.isEmpty()) insert q;

        // allow owning Case
        if ([SELECT COUNT() FROM QueueSobject WHERE QueueId=:q.Id AND SobjectType='Case'] == 0) {
            insert new QueueSobject(QueueId=q.Id, SobjectType='Case');
        }

        // add current user as member if missing
        Id me = UserInfo.getUserId();
        if ([SELECT COUNT() FROM GroupMember WHERE GroupId=:q.Id AND UserOrGroupId=:me] == 0) {
            insert new GroupMember(GroupId=q.Id, UserOrGroupId=me);
        }
        return q.Id;
    }

    private static Id anyCaseRecordType() {
        List<RecordType> rts = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Case' AND IsActive = true
            LIMIT 1
        ];
        return rts.isEmpty() ? null : rts[0].Id;
    }

    @IsTest
    static void assigns_to_running_user_and_logs() {
        // ---- SETUP DML (queue, membership) ----
        Id qId = ensureQueueWithMe();
        Id me  = UserInfo.getUserId();

        // ---- NON-SETUP DML in a separate context to avoid Mixed DML ----
        System.runAs(new User(Id = me)) {
            // Create valid Case (DML often requires Status + Origin)
            Case c = new Case(
                Subject = 'Smoke',
                Origin  = 'Phone',
                Status  = 'New',
                OwnerId = qId
            );
            Id rt = anyCaseRecordType();
            if (rt != null) c.put('RecordTypeId', rt); // dynamic to avoid compile check
            insert c;

            // Call the invocable
            CaseAssignmentService.Request req = new CaseAssignmentService.Request();
            req.caseId = c.Id;
            req.queueDeveloperName = 'Support_Tier_1';

            Test.startTest();
            List<CaseAssignmentService.Response> out =
                CaseAssignmentService.assignRoundRobin(new List<CaseAssignmentService.Request>{ req });
            Test.stopTest();

            System.assertEquals(1, out.size(), 'one response expected');
            System.assertEquals(c.Id, out[0].caseId);

            // Verify reassignment to running user
            Case c2 = [SELECT Id, OwnerId FROM Case WHERE Id = :c.Id];
            System.assertEquals(UserInfo.getUserId(), c2.OwnerId, 'Case should be assigned to running user');

            // Verify one triage log
            Integer logs = [SELECT COUNT() FROM Triage_Log__c WHERE Case__c = :c.Id];
            System.assertEquals(1, logs, 'one triage log expected');
        }
    }
}