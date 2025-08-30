public with sharing class CaseAssignmentService {
    // ----------------------------
    // Invocable wrapper
    // ----------------------------
    public class Request {
        @InvocableVariable(required=false)
        public Id caseId; // optional single case support

        @InvocableVariable(required=false)
        public List<Id> caseIds; // preferred: pass a list from Flow

        @InvocableVariable(required=false)
        public String queueDeveloperName; // optional override
    }

    public class Response {
        @InvocableVariable
        public Id caseId;

        @InvocableVariable
        public Id newOwnerId;

        @InvocableVariable
        public String message;
    }

    private static final String QUEUE_DEV_NAME = 'Support_Tier_1';

    // ----------------------------
    // Entry point for Flow
    // ----------------------------
    @InvocableMethod(label='Assign Cases Round Robin' description='Assigns Case(s) to the next agent in the queue and logs Triage.')
    public static List<Response> assignRoundRobin(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<Response>();
        }

        // Collect Case Ids
        Set<Id> caseIds = new Set<Id>();
        String devName = null;
        for (Request r : requests) {
            if (devName == null && String.isNotBlank(r.queueDeveloperName)) devName = r.queueDeveloperName;
            if (r.caseId != null) caseIds.add(r.caseId);
            if (r.caseIds != null) caseIds.addAll(r.caseIds);
        }
        if (caseIds.isEmpty()) {
            throw new AuraHandledException('No Case Ids were provided to CaseAssignmentService.assignRoundRobin.');
        }
        if (String.isBlank(devName)) devName = QUEUE_DEV_NAME;

        // Load target Cases that are still owned by queue (or anyone, your choice)
        List<Case> cases = [
            SELECT Id, OwnerId, Triage_Status__c, Region__c, Priority
            FROM Case
            WHERE Id IN :caseIds
            FOR UPDATE
        ];
        if (cases.isEmpty()) {
            return new List<Response>();
        }

        // Resolve queue + its active members
        Id queueId = resolveQueueId(devName);
        List<User> agents = getActiveQueueUsers(queueId);
        if (agents.isEmpty()) {
            throw new AuraHandledException('Queue has no active user members. Add users to the queue: ' + devName);
        }

        // Build a "least recently assigned" map using Triage_Log__c (latest per user)
        Map<Id, Datetime> lastAssignedByUser = getLastAssignedTimes(agents);

        // Assignment loop
        List<Case> updates = new List<Case>();
        List<Triage_Log__c> logs = new List<Triage_Log__c>();
        List<Response> results = new List<Response>();

        for (Case c : cases) {
            Id nextOwner = pickNextOwner(agents, lastAssignedByUser);

            c.OwnerId = nextOwner;
            updates.add(c);

            Triage_Log__c log = new Triage_Log__c(
                Case__c = c.Id,
                Assigned_To__c = nextOwner,
                Assignment_Date__c = System.now()
            );
            logs.add(log);

            // update in-memory "last assigned" so next case rotates
            lastAssignedByUser.put(nextOwner, System.now());

            Response r = new Response();
            r.caseId = c.Id;
            r.newOwnerId = nextOwner;
            r.message = 'Assigned via round-robin';
            results.add(r);
        }

        // DML
        if (!updates.isEmpty()) update updates;
        if (!logs.isEmpty()) insert logs;

        return results;
    }

    // ----------------------------
    // Helpers
    // ----------------------------

    // Finds Group (Queue) by DeveloperName and returns Id
    private static Id resolveQueueId(String developerName) {
        List<Group> rows = [
        SELECT Id FROM Group
        WHERE DeveloperName = :developerName AND Type = 'Queue'
        LIMIT 1
    ];
    if (rows.isEmpty()) {
        throw new AuraHandledException('Queue not found: ' + developerName);
    }
    return rows[0].Id;
}
    

    // Returns active User members of the queue (ignores other group members)
    private static List<User> getActiveQueueUsers(Id queueId) {
        List<GroupMember> members = [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE GroupId = :queueId
        ];

        Set<Id> userIds = new Set<Id>();
        for (GroupMember m : members) {
            if (m.UserOrGroupId.getSObjectType() == User.SObjectType) {
                userIds.add(m.UserOrGroupId);
            }
        }
        if (userIds.isEmpty()) return new List<User>();

        return [
            SELECT Id, Name, IsActive
            FROM User
            WHERE Id IN :userIds AND IsActive = true
            ORDER BY Name
        ];
    }

    // Get last assignment datetime per user from Triage_Log__c
    private static Map<Id, Datetime> getLastAssignedTimes(List<User> agents) {
        Map<Id, Datetime> lastMap = new Map<Id, Datetime>();
        if (agents.isEmpty()) return lastMap;

        Set<Id> uIds = new Set<Id>();
        for (User u : agents) uIds.add(u.Id);

        // Latest log per user
        AggregateResult[] ar = [
            SELECT Assigned_To__c a, MAX(Assignment_Date__c) d
            FROM Triage_Log__c
            WHERE Assigned_To__c IN :uIds
            GROUP BY Assigned_To__c
        ];
        for (AggregateResult row : ar) {
            lastMap.put((Id)row.get('a'), (Datetime)row.get('d'));
        }
        // Ensure all users exist in map
        for (User u : agents) {
            if (!lastMap.containsKey(u.Id)) lastMap.put(u.Id, null);
        }
        return lastMap;
    }

    // Pick user with the OLDEST (or null) last assignment time
    private static Id pickNextOwner(List<User> agents, Map<Id, Datetime> lastAssignedByUser) {
        Id winner;
        Datetime oldest = Datetime.now(); // any future value will be "older" check
        // prefer users who never received an assignment (null)
        for (User u : agents) {
            Datetime last = lastAssignedByUser.get(u.Id);
            if (last == null) return u.Id;
            if (last < oldest) {
                oldest = last;
                winner = u.Id;
            }
        }
        // fallback to first agent
        if (winner == null && !agents.isEmpty()) winner = agents[0].Id;
        return winner;
    }
}