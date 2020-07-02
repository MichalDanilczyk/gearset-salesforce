/******************************************************************************
* @author       Silvan Sholla
* @date         9/9/2019
* @description  scramble all accounts except for RT: Boutique
*               Scrambling Details
*               First Name = SF ID + First letter of the First Name
*               Last Name = SF ID + First letter of Last Name Name
*               Full Name = New First Name + New Last Name
******************************************************************************/

public class BatchAccountScrambler implements
  Database.Batchable<sObject>, Schedulable {
  private Boolean skipTriggersOnAccount;
  private String query = 'SELECT Id, FirstName, LastName ' +
                                    'FROM Account ' +
                                    'WHERE RecordTypeId != \'' + RecordTypeHelper.getRTId('Account', 'RICSC_Boutique') +'\' ';
  public static final Integer MAX_SCOPE = 100;

  public BatchAccountScrambler(Boolean skipParam, String queryStr) {
    this.query = queryStr == null ? this.query : queryStr;
    skipTriggersOnAccount = skipParam;
  }

  public void execute(SchedulableContext sc) {
    BatchAccountScrambler b = new BatchAccountScrambler(true, query);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(query);
  }
  public void execute(Database.BatchableContext bc, List<Account> scope)  {
    try {
        for (Account account : scope) {
           if(!String.isBlank(account.FirstName)){
            account.FirstName = account.Id+''+account.FirstName.substring(0,1);
           }

           if(!String.isBlank(account.LastName)){
            account.LastName = account.Id+''+account.LastName.substring(0,1);
           }
        }

        if(skipTriggersOnAccount){
            TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }
        Database.SaveResult[] srList = Database.update(scope,false);
        UtilityLogger.logAllErrors(srList, false, 'BatchAccountScrambler', 'execute');
        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }

    } catch(Exception e) {
        UtilityLogger.logException(e,e.getMessage(),'BatchAccountScrambler','execute');
    }
  }
  public void finish(Database.BatchableContext bc){
  }
}