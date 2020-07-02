public class BatchConventionRateCalculation implements Database.Batchable<SObject>, Schedulable {

  public static final Integer MAX_SCOPE = 100;
  private String query = 'SELECT Id, RICSC_CurrencyKey__c, RICSC_Maison__c, RICSC_ExtCreationDate__c, RICSC_AmountWithTaxEUR__c, RICSC_AmountWithTax__c, RICSC_CurrencyRateEUR__c FROM RICSC_Transaction__c WHERE RICSC_AmountWithTax__c != null AND RICSC_CurrencyKey__c != null AND RICSC_Maison__c != null';
  private Boolean skipTriggersOnTransaction;

  public BatchConventionRateCalculation(Boolean skipParam, String queryStr) {
    this.query = queryStr == null ? this.query : queryStr;
    skipTriggersOnTransaction = skipParam;
  }

  public Iterable<SObject> start(Database.BatchableContext bc) {
      return Database.getQueryLocator(query);
  }

  public void execute(SchedulableContext sc) {
    BatchConventionRateCalculation b = new BatchConventionRateCalculation(false, null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public void execute(Database.BatchableContext bc, List<RICSC_Transaction__c> scope) {
    Set<String> currencyISO = new Set<String>();
    for(RICSC_Transaction__c tr : scope){
      currencyISO.add(tr.RICSC_CurrencyKey__c);
    }
    UtilityTransaction.calculateConventionRate(scope, currencyISO);

    if(skipTriggersOnTransaction){
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',true);
    }
    Database.SaveResult[] srList = Database.update(scope,false);
    UtilityLogger.logAllErrors(srList, false, 'BatchConventionRateCalculation', 'execute');
    if(skipTriggersOnTransaction){
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',false);
    }

  }

  public void finish(Database.BatchableContext bc) {
  }
}