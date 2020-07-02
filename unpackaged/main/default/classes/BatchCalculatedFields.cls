public class BatchCalculatedFields implements Database.Batchable<SObject>, Schedulable {

    public static final Integer MAX_SCOPE = 100;
    private Set<String> recordTypeSet = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
    private String query = 'SELECT Id, RecordTypeId, RICSC_GoldenRecord__c, RICSC_Turnover__c, RICSC_ClientFlag__c, RICSC_GlobalSegment__c, RICSC_Vip__c, RICSC_ECard__c, RICSC_Notes__c, RICSC_SpotNotes__c, RICSC_ProductOfInterests__c, RICSC_CollectionOfInterests__c,RICSC_Hobbies__c,RICSC_LocalVIP__c FROM Account';
    private Boolean skipTriggersOnAccount = false;

    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public BatchCalculatedFields(Boolean skipParam, String queryStr) {
      this.query = queryStr == null ? this.query : queryStr;
      skipTriggersOnAccount = skipParam;
    }

    public void execute(SchedulableContext sc) {
        BatchCalculatedFields b = new BatchCalculatedFields(false, null);
        Database.executeBatch(b, MAX_SCOPE);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
      try{

        Set<Id> allScopeAccIds = new Set<Id>();
        List<Account> accountsAfterCalculatedFields = new List<Account>();
        Set<Account> vipAccs = new Set<Account>();

        for(Account ac : scope){
          allScopeAccIds.add(ac.Id);
        }

        // First of all we do the fields calculation
        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }

        accountsAfterCalculatedFields = CalculatingFieldsHandler.computeFieldsFromTransactionRecords(allScopeAccIds);
        update accountsAfterCalculatedFields;

        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
        }

        // We also calculate concatenated fields on GR_G account in scope
        accountsAfterCalculatedFields = [SELECT Id, RecordTypeId, RICSC_GoldenRecord__c, RICSC_Turnover__c, RICSC_ClientFlag__c, RICSC_GlobalSegment__c, RICSC_Vip__c, RICSC_ECard__c, RICSC_Notes__c, RICSC_SpotNotes__c, RICSC_ProductOfInterests__c, RICSC_CollectionOfInterests__c,RICSC_Hobbies__c,RICSC_LocalVIP__c FROM Account WHERE Id IN: allScopeAccIds];
        for(Account ac : accountsAfterCalculatedFields){
          if (ac.RICSC_Turnover__c != null || ac.RICSC_ClientFlag__c != null || ac.RICSC_GlobalSegment__c != null){
            vipAccs.add(ac);
          }
        }

        Map<Id,CalculatingFieldsHandler.CalculatedAccountFieldCont> calculatedValuesXGRgId = new Map <Id,CalculatingFieldsHandler.CalculatedAccountFieldCont>();
        CalculatingFieldsHandler.computeConcatenatedFieldsOnGR(allScopeAccIds,calculatedValuesXGRgId);

        // Based on the previous calculations we also decide if the user is VIP
        CalculatingFieldsHandler.computeVipFlag(vipAccs,calculatedValuesXGRgId);

        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }

        update CalculatingFieldsHandler.getComputedAccounts(calculatedValuesXGRgId.values());

        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
        }

      } catch(Exception e) {
        UtilityLogger.logException(e,e.getMessage(),'BatchCalculatedFields','execute');
      }
    }

    public void finish(Database.BatchableContext bc) {
    }
}