public class BatchLocalisationPropagation implements Database.Batchable<SObject>, Schedulable {

    public static final Integer MAX_SCOPE = 100;
    private String recordid = UtilityConstants.ACCOUNTBOUTIQUE_RT_ID;
    private String query = 'SELECT Id,RICSC_Maison__c,RICSC_CountryofOrigin__c,RICSC_Localisation__c FROM Account WHERE RecordTypeId = :recordid';
    private Boolean skipTriggersOnAccount = false;

    public BatchLocalisationPropagation(Boolean skipParam, String queryStr) {
      skipTriggersOnAccount = skipParam;
      this.query = queryStr == null ? this.query : queryStr;
    }

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc) {
        BatchLocalisationPropagation b = new BatchLocalisationPropagation(false, null);
        Database.executeBatch(b, MAX_SCOPE);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
      try{
        for (Account acc : scope){
          acc.RICSC_Localisation__c = Utility.getLocalisationId(acc.RICSC_Maison__c, acc.RICSC_CountryOfOrigin__c);
        }

        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }
        Database.SaveResult[] srList = Database.update(scope,false);
        UtilityLogger.logAllErrors(srList, false, 'BatchLocalisationPropagation', 'execute');
        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
        }
        }
     catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchLocalisationPropagation','execute');
    }
  }

    public void finish(Database.BatchableContext bc) {
    }
}