/******************************************************************************
* @author       Silvan Sholla
* @date         9/1/2020
* @description  Calculation of reference Market Region for VCA Maison
******************************************************************************/

public class BatchVCAReferenceMarketRegion implements
  Database.Batchable<sObject>, Schedulable {
  private Boolean skipTriggersOnAccount;
  private String query = 'SELECT Id,RICSC_ReferenceBoutique__c,RecordType.Name ' +
                         'FROM Account ' +
                         'WHERE RecordTypeId = \'' + RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) +'\' AND '+
                         'RICSC_IsGoldenRecord__c = true AND RICSC_HasLocalRecords__c = false AND RICSC_ReferenceBoutique__c != null';

  public static final Integer MAX_SCOPE = 100;

  public BatchVCAReferenceMarketRegion(Boolean skipParam, String queryStr) {
    this.query = queryStr == null ? this.query : queryStr;
    skipTriggersOnAccount = skipParam;
  }

  public void execute(SchedulableContext sc) {
    BatchVCAReferenceMarketRegion b = new BatchVCAReferenceMarketRegion(true, query);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }
  public void execute(Database.BatchableContext bc, List<Account> scope)  {
    try {
      Set<Id> relatedAccountsIds = new Set<Id>();
      for (Account acc : scope) {
        if(acc.RICSC_ReferenceBoutique__c != null){
          relatedAccountsIds.add(acc.Id);
        }
      }
      if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      }
      Database.SaveResult[] srList = Database.update(CalculatingFieldsHandler.referenceMarketCalculation(relatedAccountsIds),false);
      UtilityLogger.logAllErrors(srList, false, 'BatchVCAReferenceMarketRegion', 'execute');
      if(skipTriggersOnAccount){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      }
    } catch(Exception e) {
        UtilityLogger.logException(e,e.getMessage(),'BatchVCAReferenceMarketRegion','execute');
    }
  }
  public void finish(Database.BatchableContext bc){
  }
}