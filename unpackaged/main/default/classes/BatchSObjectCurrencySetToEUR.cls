/************************************************************************************
* @author       Silvan Sholla
* @date         9/Nov/2019
* @description  Batch to set the currecy key to EUR for Account,Transaction Object
*
***************************************************************************************/

global class BatchSObjectCurrencySetToEUR implements
  Database.Batchable<sObject>, Schedulable {
  private String sapcrm = UtilityConstants.SOURCE_CRM_SAP;
  private Set<String> recordTypeSet = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
  private Boolean skipTriggersOnRelatedObjects;
  private String query = 'SELECT CurrencyIsoCode FROM Account WHERE RecordTypeId IN: recordTypeSet';
  public static final Integer MAX_SCOPE = 100;

  public BatchSObjectCurrencySetToEUR(Boolean skipParam, String queryStr) {
    skipTriggersOnRelatedObjects = skipParam;
    this.query = queryStr == null ? this.query : queryStr;
  }

  public void execute(SchedulableContext sc) {
    BatchSObjectCurrencySetToEUR b = new BatchSObjectCurrencySetToEUR(false, null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }
  global void execute(Database.BatchableContext bc, List<SObject> scope)  {
    try {
      Set<Id> accIds = new Set<Id>();
      Set<SObject> objectsToUpdate = new Set<SObject>();

      for(SObject obj : scope){
        obj.put('CurrencyIsoCode','EUR');
        objectsToUpdate.add(obj);
      }

      if (objectsToUpdate.size()>0){

        Id sId = scope[0].get('Id').toString();
        String sobjectType = sId.getSObjectType().getDescribe().getName();

          if(skipTriggersOnRelatedObjects){
            TRG_TriggerDispatcher.skipTriggerMap.put(sobjectType,true);
          }
          List<SObject> objectsToBeUpdated = new List<SObject>(objectsToUpdate);
          Database.SaveResult[] srList = Database.update(objectsToBeUpdated,false);
          UtilityLogger.logAllErrors(srList, false, 'BatchTransactionCurrencySetToEUR', 'execute');

          if(skipTriggersOnRelatedObjects){
            TRG_TriggerDispatcher.skipTriggerMap.put(sobjectType,false);
          }
      }

    } catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchTransactionCurrencySetToEUR','execute');
    }
  }
  global void finish(Database.BatchableContext bc){
  }
}