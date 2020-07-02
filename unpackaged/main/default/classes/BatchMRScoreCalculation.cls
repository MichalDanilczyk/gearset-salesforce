/************************************************************************************
* @author       Dimitris Rakantas
* @date         15/11/2019
* @description  Calculation of MR Turnover and Frequency on Accounts

***************************************************************************************/

public class BatchMRScoreCalculation implements
  Database.Batchable<sObject>, Schedulable {
  private Boolean skipTriggersOnAccount;
  public static final Integer MAX_SCOPE = 100;
  private String query = 'SELECT id,RICSC_MRScoreTurnover__c,RICSC_MRScoreFrequency__c FROM Account where isPersonAccount = true';

  public BatchMRScoreCalculation(Boolean skipParam, String queryStr) {
    skipTriggersOnAccount = skipParam;
    this.query = queryStr == null ? this.query : queryStr;
  }

  public void execute(SchedulableContext sc) {
    BatchMRScoreCalculation b = new BatchMRScoreCalculation(false, null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator(this.query);
  }
  public void execute(Database.BatchableContext bc, List<Account> scope)  {
    try {

      Date before5years = System.now().addYears(-5).date();

      List<Id> accountIds = new List<Id>();
      for (Account a : scope){
      	accountIds.add(a.Id);
      }

      Map<id,Account> accountTransactions= new Map<id, Account>([SELECT Id, (SELECT id,RICSC_GoldenRecord__c,RICSC_AmountWithTaxEUR__c,RICSC_TransactionDate__c,RICSC_SerialNumber__c,
                                              RICSC_Maison__c,RICSC_TransactionCategory__c from RICSC_TransactionsAccount__r),
                                              (SELECT id,RICSC_Account__c,RICSC_AmountWithTaxEUR__c,RICSC_TransactionDate__c,RICSC_SerialNumber__c,
                                              RICSC_Maison__c,RICSC_TransactionCategory__c from RICSC_TransactionsGoldenRecord__r)
                                              FROM Account where Id in :accountIds]);


      Map<id,Set<Date>> transactionsDatesMap = new Map<id,Set<Date>>();

      for (Account a : scope){
        a.RICSC_MRScoreTurnover__c=0;
        a.RICSC_MRScoreFrequency__c=0;
        transactionsDatesMap.put(a.id,new Set<Date>());
        Set<RICSC_Transaction__c> traccs = new Set<RICSC_Transaction__c>();
        if (accountTransactions.get(a.Id).RICSC_TransactionsAccount__r.size()>0){
          traccs.addAll(accountTransactions.get(a.Id).RICSC_TransactionsAccount__r);
        }
        if (accountTransactions.get(a.Id).RICSC_TransactionsGoldenRecord__r.size()>0){
          traccs.addAll(accountTransactions.get(a.Id).RICSC_TransactionsGoldenRecord__r);
        }
        for (RICSC_Transaction__c t : traccs){
          if(t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_REPAIR || (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_SALES && (t.RICSC_AmountWithTaxEUR__c == 0 || t.RICSC_AmountWithTaxEUR__c == null))){
            continue;
          }
          if (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_SALES){
              if((t.RICSC_Maison__c==UtilityConstants.MAISON_CARTIER || t.RICSC_Maison__c==UtilityConstants.MAISON_VAN_CLEEF_ARPELS) && t.RICSC_TransactionDate__c != null){
                if(t.RICSC_TransactionDate__c>=before5years){
                  if (!transactionsDatesMap.get(a.id).contains(t.RICSC_TransactionDate__c)){
                    a.RICSC_MRScoreFrequency__c++;
                    transactionsDatesMap.get(a.id).add(t.RICSC_TransactionDate__c);
                  }
                  if (t.RICSC_AmountWithTaxEUR__c == null){
                    t.RICSC_AmountWithTaxEUR__c = 0;
                  }
                  a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
                }
              }
              else if (t.RICSC_Maison__c==UtilityConstants.MAISON_JAEGER_LE_COULTRE && t.RICSC_TransactionDate__c != null){
                if (!transactionsDatesMap.get(a.id).contains(t.RICSC_TransactionDate__c)){
                  a.RICSC_MRScoreFrequency__c++;
                  transactionsDatesMap.get(a.id).add(t.RICSC_TransactionDate__c);
                }
                if (t.RICSC_AmountWithTaxEUR__c == null){
                  t.RICSC_AmountWithTaxEUR__c = 0;
                }
                a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
              }
            } else if (t.RICSC_TransactionCategory__c==UtilityConstants.TRANSACTION_TYPE_RETURN && t.RICSC_AmountWithTaxEUR__c != null){
              a.RICSC_MRScoreTurnover__c+=t.RICSC_AmountWithTaxEUR__c;
            }
          }
        }

        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        }
        Database.SaveResult[] srList = Database.update(scope,false);
        UtilityLogger.logAllErrors(srList, false, 'BatchMRScoreCalculation','execute');
        if(skipTriggersOnAccount){
          TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
        }

    } catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchMRScoreCalculation','execute');
    }
  }
  public void finish(Database.BatchableContext bc){

  }
}