public class BatchCalculateGlobalSegment implements Database.Batchable<SObject>, Schedulable {

    public static final Integer MAX_SCOPE = 100;
    private Set<String> recordTypeSet = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
    public String query = 'SELECT Id FROM Account WHERE RICSC_HasLocalRecords__c = true AND RecordTypeId IN: recordTypeSet';
    public Boolean skipTriggersOnAccount = false;

    public BatchCalculateGlobalSegment(Boolean skipParam, String queryStr){
      this.query = queryStr == null ? this.query : queryStr;
      skipTriggersOnAccount = skipParam;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc) {
        BatchCalculateGlobalSegment b = new BatchCalculateGlobalSegment(false, null);
        Database.executeBatch(b, MAX_SCOPE);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
      try{
      Map<Id,Account> scopeMap = new Map<Id,Account>(scope);
      Set<Id> grIds = scopeMap.keySet();
      UtilityAccount.calculateSegment(grIds, false, skipTriggersOnAccount);
      } catch(Exception e) {
        UtilityLogger.logException(e,e.getMessage(),'BatchCalculateGlobalSegment','execute');
      }
    }

    public void finish(Database.BatchableContext bc) {
    }
}