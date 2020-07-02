public class BatchResidenceNonResidence implements Database.Batchable<SObject>, Schedulable {

    public static final Integer MAX_SCOPE = 100;
    private String query = 'SELECT Id, RICSC_HasLocalRecords__c FROM Account';
    public Boolean skipTriggersOnAccount = false;

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }

    public BatchResidenceNonResidence(Boolean skipParam, String queryStr) {
      this.query = queryStr == null ? this.query : queryStr;
      skipTriggersOnAccount = skipParam;
    }

    public void execute(SchedulableContext sc) {
      BatchResidenceNonResidence b = new BatchResidenceNonResidence(false, null);
      Database.executeBatch(b, MAX_SCOPE);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
      Set<Id> accountsWithoutLocals = new Set<Id>();
      Set<Id> accountsWithLocals = new Set<Id>();
      for(Account acc : scope){
        if(acc.RICSC_HasLocalRecords__c) {
          accountsWithLocals.add(acc.Id);
        }
        else {
          accountsWithoutLocals.add(acc.Id);
        }
      }

      if(skipTriggersOnAccount){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      }

      Database.SaveResult[] srList = Database.update(CalculatingFieldsHandler.computeResidenceNonResidence(accountsWithoutLocals, 'RICSC_Account__c', true),false);
      UtilityLogger.logAllErrors(srList, false, 'BatchResidenceNonResidence','execute');

      srList = Database.update(CalculatingFieldsHandler.computeResidenceNonResidence(accountsWithLocals, 'RICSC_GR__c', true),false);
      UtilityLogger.logAllErrors(srList, false, 'BatchResidenceNonResidence','execute');

      if(skipTriggersOnAccount){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
      }
    }

    public void finish(Database.BatchableContext bc) {

    }
}