/************************************************************************************
* @author       Dimitrios Rakantas
* @date         19/Nov/2019
* @description  Batch for propagating the consents on the related accounts and vice versa.
***************************************************************************************/

public class BatchConsentsOnRecords implements
  Database.Batchable<sObject>, Schedulable {
  private Boolean skipTriggersOnAccount;
  private String query = 'SELECT Id FROM Account WHERE isPersonAccount = true';
  public static final Integer MAX_SCOPE = 100;

  public BatchConsentsOnRecords(Boolean skipParam, String queryStr) {
    this.query = queryStr == null ? this.query : queryStr;
    skipTriggersOnAccount = skipParam;
  }

  public void execute(SchedulableContext sc) {
    BatchConsentsOnRecords b = new BatchConsentsOnRecords(false, null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Account> scope)  {
    try {
        List<Account> accsList= new List<Account>([SELECT Id,RICSC_IsGoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c,
        RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c,RICSC_HasLocalRecords__c,
        (SELECT RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c,RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
        FROM RICSC_AccountGoldenRecord__r) FROM Account WHERE id IN :scope AND RICSC_HasLocalRecords__c = true]);
        List<Account> accountsToUpdate = new List<Account>();
        for(Account golden : accsList){
          Account  master = golden;
          for (Account slave : golden.RICSC_AccountGoldenRecord__r){
            if(master.RICSC_ConsentTimestamp__c == null || master.RICSC_ConsentTimestamp__c < slave.RICSC_ConsentTimestamp__c){
              master = slave;
            }
          }
          if(master.RICSC_ConsentTimestamp__c == null){
            continue;
          }
          golden.RICSC_ConsentTimestamp__c = master.RICSC_ConsentTimestamp__c;
          golden.RICSC_CanBeContacted__c = master.RICSC_CanBeContacted__c;
          golden.RICSC_ElectronicContact__c = master.RICSC_ElectronicContact__c;
          golden.RICSC_PostalContact__c = master.RICSC_PostalContact__c;
          golden.RICSC_VoiceContact__c = master.RICSC_VoiceContact__c;
          accountsToUpdate.add(golden);
          for (Account slave : golden.RICSC_AccountGoldenRecord__r){
            slave.RICSC_ConsentTimestamp__c = master.RICSC_ConsentTimestamp__c;
            slave.RICSC_CanBeContacted__c = master.RICSC_CanBeContacted__c;
            slave.RICSC_ElectronicContact__c = master.RICSC_ElectronicContact__c;
            slave.RICSC_PostalContact__c = master.RICSC_PostalContact__c;
            slave.RICSC_VoiceContact__c = master.RICSC_VoiceContact__c;
            accountsToUpdate.add(slave);
          }
        }

        if(accountsToUpdate.size() > 0){
          if(skipTriggersOnAccount){
              TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
          }

          Database.SaveResult[] srList = Database.update(accountsToUpdate,false);
          UtilityLogger.logAllErrors(srList, false, 'BatchConsentsOnRecords', 'execute');

          if(skipTriggersOnAccount){
            TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
          }
        }
    } catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchConsentsOnRecords','execute');
    }
  }
  public void finish(Database.BatchableContext bc){
  }
}