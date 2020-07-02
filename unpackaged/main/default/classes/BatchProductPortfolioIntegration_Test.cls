@isTest
private class BatchProductPortfolioIntegration_Test {
    @testSetup
    static void setup() {

      TRG_TriggerDispatcher.skipTriggerMap.put('TransactionTriggerHandler.ProductPortfolioIntegrationTRG',true);
      UtilityTests.testSetup();

      List<RICSC_Transaction__c> transactions = new List<RICSC_Transaction__c>();
      List<Asset> assets = new List<Asset>();

      Account transactionOwner = UtilityTests.getPersonAccount();
      transactionOwner.LastName = 'AccountTransactionOwner';
      insert transactionOwner;

      Account transactionOwnerThatDoesntHaveAnyAsset = UtilityTests.getPersonAccount();
      transactionOwnerThatDoesntHaveAnyAsset.LastName = 'transactionOwnerThatDoesntHaveAnyAsset';
      insert transactionOwnerThatDoesntHaveAnyAsset;

      Product2 pr = new Product2(Name = 'testProduct');
      insert pr;

      RICSC_Transaction__c trc = UtilityTests.getTransaction();
      trc.RICSC_CountryOfOrigin__c = 'France';
      trc.RICSc_Account__c = transactionOwner.Id;
      trc.RICSC_Maison__c = 'Cartier';
      trc.RICSC_Channel__c = 'Boutique';
      trc.RICSC_CurrencyKey__c = 'EUR';
      trc.RICSC_SerialNumber__c = '123456';
      trc.RICSC_TransactionNumber__c = 'EXISTINGASSET';
      trc.RICSC_AmountWithTax__c = 250.0;
      trc.RICSC_Channel__c = 'Boutique';
      trc.RICSC_TransactionCategory__c = 'Sale';
      trc.RICSC_ExtCreationDate__c = Date.newInstance(2018, 12, 9);
      transactions.add(trc);

      RICSC_Transaction__c trc2 = UtilityTests.getTransaction();
      trc2.RICSC_CountryOfOrigin__c = 'France';
      trc2.RICSc_Account__c = transactionOwner.Id;
      trc2.RICSC_Maison__c = 'Cartier';
      trc2.RICSC_Channel__c = 'Boutique';
      trc2.RICSC_CurrencyKey__c = 'EUR';
      trc2.RICSC_SerialNumber__c = '123457';
      trc2.RICSC_TransactionCategory__c = 'Sale';
      trc2.RICSC_ProductName__c = pr.id;
      trc2.RICSC_TransactionNumber__c = 'NEGATIVEAMOUNT';
      trc2.RICSC_AmountWithTax__c = -250.0;
      trc2.RICSC_ExtCreationDate__c = Date.newInstance(2018, 12, 9);
      transactions.add(trc2);

      RICSC_Transaction__c trc3 = UtilityTests.getTransaction();
      trc3.RICSC_CountryOfOrigin__c = 'France';
      trc3.RICSc_Account__c = transactionOwner.Id;
      trc3.RICSC_Maison__c = 'Cartier';
      trc3.RICSC_Channel__c = 'Boutique';
      trc3.RICSC_CurrencyKey__c = 'EUR';
      trc3.RICSC_SerialNumber__c = '01010';
      trc3.RICSC_ProductName__c = pr.id;
      trc3.RICSC_TransactionNumber__c = '1111';
      trc3.RICSC_TransactionCategory__c = 'Sale';
      trc3.RICSC_AmountWithTax__c = -250.0;
      trc3.RICSC_ExtCreationDate__c = Date.newInstance(2018, 12, 9);
      transactions.add(trc3);

      RICSC_Transaction__c trc4 = UtilityTests.getTransaction();
      trc4.RICSC_CountryOfOrigin__c = 'France';
      trc4.RICSc_Account__c = transactionOwnerThatDoesntHaveAnyAsset.Id;
      trc4.RICSC_Maison__c = 'Cartier';
      trc4.RICSC_Channel__c = 'Boutique';
      trc4.RICSC_CurrencyKey__c = 'EUR';
      trc4.RICSC_TransactionCategory__c = 'Sale';
      trc4.RICSC_SerialNumber__c = '2222';
      trc4.RICSC_ProductName__c = pr.id;
      trc4.RICSC_TransactionNumber__c = '1111';
      trc4.RICSC_AmountWithTax__c = -250.0;
      trc4.RICSC_ExtCreationDate__c = Date.newInstance(2018, 12, 9);
      transactions.add(trc4);

      insert transactions;

      Asset ast1 = new Asset();
      ast1.Name = 'asset2';
      ast1.SerialNumber = '123456';
      ast1.AccountId = transactionOwner.Id;
      assets.add(ast1);

      Asset ast2 = new Asset();
      ast2.Name = 'asset3';
      ast2.SerialNumber = '1234568';
      ast2.RICSC_GoldenRecord__c = transactionOwner.Id;
      assets.add(ast2);

      Asset ast3 = new Asset();
      ast3.Name = 'asset4';
      ast3.SerialNumber = '01010';
      ast3.RICSC_GoldenRecord__c = transactionOwner.Id;
      assets.add(ast3);

      insert assets;
    }

    static testmethod void creationOfNewAssetBecauseTheIdMissmatch() {
      Test.startTest();
      BatchProductPortfolioIntegration uca = new BatchProductPortfolioIntegration(false,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      System.assertEquals([SELECT Name FROM Asset WHERE SerialNumber = '123457'].Name,'PP-123457');
    }

    static testmethod void updateTheAssetBecauseTheIdMatchPossitiveAmount() {
      Test.startTest();
      BatchProductPortfolioIntegration uca = new BatchProductPortfolioIntegration(false,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      //it updates the asset that match with the latest tranasction in the list because its possible to have more than one transaction
      //that the serialnumbers and lookup match so the one updates its the last one
      Asset updatedAsset = [SELECT Name,RICSC_ProductsReturned__c FROM Asset WHERE SerialNumber = '123456'];
      System.assertEquals(updatedAsset.Name,'PP-123456');
      System.assertEquals(updatedAsset.RICSC_ProductsReturned__c,false);
    }

    static testmethod void updateTheAssetBecauseTheIdMatchNegativeAmount() {
      Test.startTest();
      BatchProductPortfolioIntegration uca = new BatchProductPortfolioIntegration(false,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      //it updates the asset that match with the latest tranasction in the list because its possible to have more than one transaction
      //that the serialnumbers and lookup match so the one updates its the last one
      Asset updatedAsset = [SELECT Name,RICSC_ProductsReturned__c FROM Asset WHERE SerialNumber = '01010'];
      System.assertEquals(updatedAsset.Name,'PP-01010');
      System.assertEquals(updatedAsset.RICSC_ProductsReturned__c,true);
    }

    static testmethod void createAssetBecauseThereIsNotAnyWithSameLookUp() {
      Test.startTest();
      BatchProductPortfolioIntegration uca = new BatchProductPortfolioIntegration(false,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      System.assertEquals([SELECT Name FROM Asset WHERE SerialNumber = '2222'].Name,'PP-2222');
    }

    static testmethod void createAssetBecauseThereIsNotAnyWithSameLookUpTriggersSkipped() {
      Test.startTest();
      BatchProductPortfolioIntegration uca = new BatchProductPortfolioIntegration(true,null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      System.assertEquals([SELECT Name FROM Asset WHERE SerialNumber = '2222'].Name,'PP-2222');
    }

}