/******************************************************************************
* @author       Silvan Sholla
* @date         28/11/2019
* @description  Creation or the update of Assets based on the following criteria
*               ** if there is a match of the Serial numbers then:
                Verify if the amount on the transaction is positive
                ** if yes = update Product Portfolio (Asset) with the values from Transaction
                else = Mark Product Portfolio (Asset) field Product Refunded
                ** if there is no match of the Serial numbers then:

                Create a new record in Product Portfolio (Asset) based
                on the fields queried in the transaction & mapping of
                Product Portfolio fields, link it to the same account as the transaction
                Insert Transaction ID in the lookup to link the records
******************************************************************************/

public without sharing class ProductPortfolioIntegration {
  public static List<Asset> productPortfolioTransactionPropagation(List<RICSC_Transaction__c> transactionList){


    Set<Id> accIdsGR = new Set<Id>();
    List<RICSC_Transaction__c> involvedTransaction = new List<RICSC_Transaction__c>();
    Map<Id, Account> assetsByAccountId = new Map<Id, Account>();
    Map<String,Asset> assetsToBeUpdatedMap = new Map<String,Asset>();

    //the golden record account will be always filled except the case it doesnt have any account id
    for(RICSC_Transaction__c tr : (List<RICSC_Transaction__c>) transactionList){
      if(tr.RICSC_GoldenRecord__c != null){
        accIdsGR.add(tr.RICSC_GoldenRecord__c);
        involvedTransaction.add(tr);
      }
    }

    if(accIdsGR.size() >0){
      if (Schema.sObjectType.Asset.isAccessible()) {
        // it creates a map with account id as key and list of assets as value per each id
        assetsByAccountId = new Map<Id, Account>([SELECT Id,(SELECT Id,SerialNumber,RICSC_GoldenRecord__c,AccountId FROM RICSC_AssetsGoldenRecord__r) FROM Account WHERE Id IN :accIdsGR ]);
      }
      for(RICSC_Transaction__c tr : involvedTransaction){
        Boolean hasAsset = false;
        //it checks if the certain account has related assets , in case it has and serial number
        //matches the assets it being updated based on the transaction
        if(assetsByAccountId.get(tr.RICSC_GoldenRecord__c).RICSC_AssetsGoldenRecord__r != null){
          for(Asset ast: assetsByAccountId.get(tr.RICSC_GoldenRecord__c).RICSC_AssetsGoldenRecord__r) {
            if(tr.RICSC_SerialNumber__c == ast.SerialNumber){
              hasAsset = true;
              Asset assetAfterConditionCheck = assetUpdateBasedOnTheTransaction(tr,ast);
              assetsToBeUpdatedMap.put(assetAfterConditionCheck.SerialNumber,assetAfterConditionCheck);
              // assets with same serial number its not possible so in case the account got 1000 assets
              // it doesnt have to search for all if the asset with same id is in first row
              break;
            }
          }
        }

        //in case that doesnt have any asset totally create a new asset even if there is not any asset with same lookup
        if(!hasAsset){
          Asset assetAfterConditionCheck = assetCreationBasedOnTheTransaction(tr);
          assetsToBeUpdatedMap.put(assetAfterConditionCheck.SerialNumber,assetAfterConditionCheck);
        }
      }
    }
    return assetsToBeUpdatedMap.values();
  }

  public static Asset assetUpdateBasedOnTheTransaction(RICSC_Transaction__c tr,Asset ast){
    Asset updatedAsset = new Asset();

    updatedAsset.Id = ast.Id;
    updatedAsset.RICSC_GoldenRecord__c = tr.RICSC_GoldenRecord__c;
    updatedAsset.AccountId = tr.RICSC_Account__c;
    updatedAsset.Name = 'PP-'+tr.RICSC_SerialNumber__c;
    updatedAsset.RICSC_CountryOfOrigin__c = tr.RICSC_CountryOfOrigin__c;
    updatedAsset.RICSC_Maison__c = tr.RICSC_Maison__c;
    updatedAsset.RICSC_SalesAssociate__c = tr.RICSC_SalesAssociate__c;
    updatedAsset.Product2Id = tr.RICSC_ProductName__c;
    updatedAsset.PurchaseDate = tr.RICSC_TransactionDate__c;
    updatedAsset.RICSC_DistributionChannel__c = tr.RICSC_Channel__c;
    updatedAsset.RICSC_Boutique__c = tr.RICSC_Boutique__c;
    updatedAsset.RICSC_ExtCreationDate__c = tr.RICSC_ExtCreationDate__c;
    updatedAsset.RICSC_TransactionID__c = tr.Id;
    updatedAsset.SerialNumber = tr.RICSC_SerialNumber__c;
    updatedAsset.RICSC_TransactionNumber__c = tr.RICSC_TransactionNumber__c;
    updatedAsset.RICSC_AmountWithTax__c = tr.RICSC_AmountWithTax__c;
    if(tr.RICSC_AmountWithTax__c < 0){
      updatedAsset.RICSC_ProductsReturned__c = true;
    }else{
      updatedAsset.RICSC_ProductsReturned__c = false;
    }

    return updatedAsset;
  }

  public static Asset assetCreationBasedOnTheTransaction(RICSC_Transaction__c tr){
    Asset updatedAsset = new Asset();
    updatedAsset.RICSC_GoldenRecord__c = tr.RICSC_GoldenRecord__c;
    updatedAsset.AccountId = tr.RICSC_Account__c;
    updatedAsset.RICSC_CountryOfOrigin__c = tr.RICSC_CountryOfOrigin__c;
    updatedAsset.RICSC_Maison__c = tr.RICSC_Maison__c;
    updatedAsset.Name = 'PP-'+tr.RICSC_SerialNumber__c;
    updatedAsset.RICSC_SalesAssociate__c = tr.RICSC_SalesAssociate__c;
    updatedAsset.Product2Id = tr.RICSC_ProductName__c;
    updatedAsset.PurchaseDate = tr.RICSC_TransactionDate__c;
    updatedAsset.SerialNumber = tr.RICSC_SerialNumber__c;
    updatedAsset.RICSC_DistributionChannel__c = tr.RICSC_Channel__c;
    updatedAsset.RICSC_Boutique__c = tr.RICSC_Boutique__c;
    updatedAsset.RICSC_ExtCreationDate__c = tr.RICSC_ExtCreationDate__c;
    updatedAsset.RICSC_TransactionID__c = tr.Id;
    updatedAsset.RICSC_TransactionNumber__c = tr.RICSC_TransactionNumber__c;
    updatedAsset.RICSC_AmountWithTax__c = tr.RICSC_AmountWithTax__c;
    if(tr.RICSC_AmountWithTax__c < 0){
      updatedAsset.RICSC_ProductsReturned__c = true;
    }else{
      updatedAsset.RICSC_ProductsReturned__c = false;
    }
    return updatedAsset;
  }

  public static void duplicateCheckOverSerialNumber(Map<String,Asset> serialNumberAssetMap){
    List<Asset> alreadyImportedAssets = [SELECT SerialNumber,AccountId FROM Asset WHERE SerialNumber IN :serialNumberAssetMap.keySet()];
    Map<String,Asset> alreadyImportedAssetsMap = new Map<String,Asset>();
    List<Asset> assetsToBeDeleted = new List<Asset>();
    for(Asset ast : alreadyImportedAssets){
      alreadyImportedAssetsMap.put(ast.SerialNumber,ast);
    }
    List<Asset> assetsToBeImported = new List<Asset>();
    for(Asset currentAsset : serialNumberAssetMap.values()){
      if(alreadyImportedAssetsMap.keySet().contains(currentAsset.SerialNumber)){
        if(currentAsset.AccountId != null){
          currentAsset.AccountId = alreadyImportedAssetsMap.get(currentAsset.SerialNumber).AccountId;
        }
        assetsToBeDeleted.add(alreadyImportedAssetsMap.get(currentAsset.SerialNumber));
      }
    }
    // deleted the previously imported record with the same SerialNumber as the newly imported and importing the new instaid
    delete assetsToBeDeleted;
  }
}