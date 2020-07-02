/******************************************************************************
* @author       Silvan Sholla
* @date         12/11/2019
* @description  Checks the default Records based on the last modified one
*               for each account
******************************************************************************/

global class BatchDefaultRecord implements
  Database.Batchable<sObject>, Schedulable {
  private Set<String> recordTypeSet = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
  private Boolean skipTriggersOnAccRelObjs;
  private String query = 'SELECT Id,RICSC_HasLocalRecords__c,RICSC_IsGoldenRecord__c FROM Account WHERE RICSC_IsGoldenRecord__c = true AND RecordTypeId IN: recordTypeSet';
  public static final Integer MAX_SCOPE = 100;

  public BatchDefaultRecord(Boolean skipParam, String queryStr) {
    skipTriggersOnAccRelObjs = skipParam;
    this.query = queryStr == null ? this.query : queryStr;
  }

  public void execute(SchedulableContext sc) {
    BatchDefaultRecord b = new BatchDefaultRecord(false, null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }
  global void execute(Database.BatchableContext bc, List<Account> scope)  {
    try {
      Set<Id> involvedAccs = new Set<Id>();
      List<SObject> objectsToUpdate = new List<SObject>();
      for (Account acc : (List<Account>)scope){
        involvedAccs.add(acc.Id);
      }

      if(involvedAccs.size()>0){
        CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Email__c','RICSC_EmailsGR__r',involvedAccs,'RICSC_DefaultEmail__c','RICSC_DefaultGREmail__c');
        CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Address__c','RICSC_AddressesGR__r',involvedAccs,'RICSC_LRMainAddress__c','RICSC_GRMainAddress__c');
        CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Phone__c','RICSC_PhonesGR__r',involvedAccs,'RICSC_DefaultPhone__c','RICSC_DefaultGRPhone__c');
        CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_SocialMediaID__c','RICSC_SocialMediaIDsGR__r',involvedAccs,'RICSC_DefaultSocialMediaID__c','RICSC_DefaultGRSocialMediaID__c');
      }
    } catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchDefaultRecord','execute');
    }
  }
  global void finish(Database.BatchableContext bc){

  }
}