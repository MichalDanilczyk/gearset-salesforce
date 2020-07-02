/************************************************************************************
* @author       Silvan Sholla
* @date         9/9/2019
* @description  Population of Product portfolio records related to
*               an account based on linked transaction records.
*               With The Following Criteria :
*
*               1. if there is a match between transaction and asset serial number
*               and the amount with tax is possitive update asset with values
*               from transaction
*               else if there is a match with serial number but the amount with
*               tax is negative mark product refunded as true
*
*               2.If there is not match between transaction and asset serial number
*               create a new asset with the transaction fields link to the same account
***************************************************************************************/


public class BatchProductPortfolioIntegration implements
  Database.Batchable<sObject>, Schedulable {
  private Boolean skipTriggersOnAsset;
  public static final Integer MAX_SCOPE = 100;
  public String salesType = UtilityConstants.TRANSACTION_TYPE_SALES;
  private String query = 'SELECT RICSC_SerialNumber__c, Id, RICSC_Account__c, RICSC_GoldenRecord__c,'+
      'RICSC_AmountWithTax__c,RICSC_TransactionNumber__c,RICSC_ExtCreationDate__c,RICSC_Boutique__c, ' +
      'RICSC_CountryOfOrigin__c,RICSC_SalesAssociate__c,RICSC_Channel__c,RICSC_TransactionDate__c,'+
      'RICSC_ProductName__c,RICSC_Maison__c FROM RICSC_Transaction__c '+
      'WHERE RICSC_ExtCreationDate__c >=:ProductPortfolioIntegrationDate AND RICSC_TransactionCategory__c = :salesType';

  public BatchProductPortfolioIntegration(Boolean skipParam, String queryStr) {
    this.query = queryStr == null ? this.query : queryStr;
    skipTriggersOnAsset = skipParam;
  }

  public void execute(SchedulableContext sc) {
    BatchProductPortfolioIntegration b = new BatchProductPortfolioIntegration(false,null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Date  ProductPortfolioIntegrationDate = GeneralSettings__c.getOrgDefaults().RICSC_ProductPortfolioIntegrationDate__c;
    return Database.getQueryLocator(query);
  }
  public void execute(Database.BatchableContext bc, List<RICSC_Transaction__c> scope)  {
    try {
      if(skipTriggersOnAsset){
        TRG_TriggerDispatcher.skipTriggerMap.put('Asset',true);
      }

      Database.UpsertResult[] upsrList = Database.upsert(ProductPortfolioIntegration.productPortfolioTransactionPropagation(scope),false);
      //UtilityLogger.logAllErrors(srList, false, 'BatchProductPortfolioIntegration','execute');

      if(skipTriggersOnAsset){
        TRG_TriggerDispatcher.skipTriggerMap.put('Asset',false);
      }
    } catch(Exception e) {
      UtilityLogger.logException(e,e.getMessage(),'BatchProductPortfolioIntegration','execute');
    }
  }
  public void finish(Database.BatchableContext bc){

  }
}