/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on Asset object used within the trigger framework.
******************************************************************************/

public with sharing class ProductPortfolioTriggerHandler {
    public without sharing class ClassCodeCalculation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> involvedAccounts = new Set<Id>();

      if(td.isInsert || td.isUpdate){
        for(Asset ast : (List<Asset>) td.newList){
          if(ast.RICSC_GoldenRecord__c != null){
            involvedAccounts.add(ast.RICSC_GoldenRecord__c);
          }
        }
      }

      if(td.isDelete){
        for(Asset ast : (List<Asset>) td.oldList){
          if(ast.RICSC_GoldenRecord__c != null){
            involvedAccounts.add(ast.RICSC_GoldenRecord__c);
          }
        }
      }

      if(involvedAccounts.size() > 0){
        List<Account> involvedAccountList = [SELECT Id,RICSC_TransactionChannelsSelected__c,RICSC_ClassCode__c,RICSC_TotalNumberOfSales__c,RICSC_TotalNumberOfRepairs__c,(SELECT id,RICSC_TransactionID__c  FROM RICSC_AssetsGoldenRecord__r) FROM Account WHERE Id IN :involvedAccounts];
        List<Account> accountsToBeUpdated = new List<Account>();
        for(Account acc :involvedAccountList){
          Boolean hasAllAssetsWS = true;
          if(acc.getSObjects('RICSC_AssetsGoldenRecord__r') != null){
            for(Asset ast :(List<Asset>)acc.getSObjects('RICSC_AssetsGoldenRecord__r')){
              if(ast.RICSC_TransactionID__c != null){
                hasAllAssetsWS = false;
                break;
              }
            }
            if(hasAllAssetsWS){
              Account updatedAccount = new Account();
              updatedAccount.put('Id', acc.Id);
              updatedAccount.put('RICSC_ClassCode__c', UtilityConstants.CLASS_CODE_WHLSL);
              accountsToBeUpdated.add(updatedAccount);
            }
          }
        }
        update accountsToBeUpdated;
      }
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of asset based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('Assets','AccountId','RICSC_GoldenRecord__c','ProductPortfolioTriggerHandler',td.newList);
    }
  }


  /******************************************************************************
  @author Silvan Sholla
  @date 13/Jan/2020
  @description duplication of product portfolios check
               the PP being inserted from integration is allowed but then any
               existing with same serial Number is being deleted
  ******************************************************************************/
  public without sharing class DuplicateCheck implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Map<String,Asset> serialNumberAssetMap = new Map<String,Asset>();
      for(Asset ast : (List<Asset>) td.newList){
        if(ast.SerialNumber != null){
          serialNumberAssetMap.put(ast.SerialNumber,ast);
        }
      }
      ProductPortfolioIntegration.duplicateCheckOverSerialNumber(serialNumberAssetMap);
    }
  }
}