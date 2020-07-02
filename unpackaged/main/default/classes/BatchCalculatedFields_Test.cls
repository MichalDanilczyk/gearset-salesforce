@isTest
private class BatchCalculatedFields_Test {

  @testSetup
  static void setup() {
    UtilityTests.testSetup();
    List<RICSC_Localisation__c> locList = new List<RICSC_Localisation__c>();
    RICSC_Localisation__c localisationFrance = new RICSC_Localisation__c(Name = 'France',RICSC_LocalisationLevel__c = 'Country',RICSC_Maison__c = 'Cartier');
    RICSC_Localisation__c localisationMonaco = new RICSC_Localisation__c(Name = 'Monaco',RICSC_LocalisationLevel__c = 'Country',RICSC_Maison__c = 'Cartier');
    locList.add(localisationFrance);
    locList.add(localisationMonaco);

    insert locList;

    List<Contact> contactsToInsert = new List<Contact>();
    Contact newFrenchSalesAssociate = new Contact();
    newFrenchSalesAssociate.FirstName = 'Silvain';
    newFrenchSalesAssociate.LastName = 'Sola';
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    contactsToInsert.add(newFrenchSalesAssociate);

    Contact newMonacoAssociate = new Contact();
    newMonacoAssociate.FirstName = 'Silva';
    newMonacoAssociate.LastName = 'Solla';
    newMonacoAssociate.RICSC_CountryOfOrigin__c = 'Monaco';
    contactsToInsert.add(newMonacoAssociate);

    insert contactsToInsert;

    List<Account> accounts = new List<Account>();
    for(Integer i=0; i<2; i++){
      Account acc = new Account();
      if(i!=0){
        acc.RICSC_Notes__c = 'Some info about the customer';
      }
      acc.LastName = 'VanCleefAndArpelsAccount';
      acc.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_VanCleefAndArpels');
      acc.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
      acc.RICSC_DataOrigin__c = 'NOT-WS';
      accounts.add(acc);
    }
    insert accounts;
    Account boutique = UtilityTests.getAccount();
    insert boutique;

    Product2 p = new Product2(Name = 'Test Product', RICSC_Type__c = 'Watches');
    insert p;

    List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
    Account acc = accounts.get(0);

    RICSC_Transaction__c t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Italy';
    t.RICSC_ProductName__c = p.Id;
    t.RICSC_AmountWithTaxEUR__c = 1000;
    t.RICSC_Channel__c = 'Boutique';
    t.RICSC_Boutique__c = boutique.Id;
    t.RICSC_TransactionCategory__c = 'Sale';
    t.RICSC_ExtCreationDate__c = Date.today();
    transactionsList.add(t);

    acc = accounts.get(1);
    t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Italy';
    t.RICSC_ProductName__c = p.Id;
    t.RICSC_AmountWithTaxEUR__c = 1000;
    t.RICSC_Channel__c = 'Boutique';
    t.RICSC_Boutique__c = boutique.Id;
    t.RICSC_TransactionCategory__c = 'Sale';
    t.RICSC_ExtCreationDate__c = Date.today();
    transactionsList.add(t);
    t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Italy';
    t.RICSC_ProductName__c = p.Id;
    t.RICSC_AmountWithTaxEUR__c = 1000;
    t.RICSC_Channel__c = 'Boutique';
    t.RICSC_Boutique__c = boutique.Id;
    t.RICSC_TransactionCategory__c = 'Sale';
    t.RICSC_ExtCreationDate__c = Date.today();
    transactionsList.add(t);
    insert transactionsList;

    accounts.get(1).RICSC_GoldenRecord__c = accounts.get(0).Id;
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.CalculatingFields',true);
    TRG_TriggerDispatcher.skipTriggerMap.put('TransactionTriggerHandler.CalculatingFields',true);
    update accounts.get(1);
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',false);
    TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.CalculatingFields',false);
    TRG_TriggerDispatcher.skipTriggerMap.put('TransactionTriggerHandler.CalculatingFields',false);
}

  static testmethod void calculateFields() {
    Test.startTest();
    BatchCalculatedFields b = new BatchCalculatedFields(true, null);
    Id batchId = Database.executeBatch(b);
    Test.stopTest();
    List<Account> accounts = [SELECT Id, RICSC_Notes__c, RICSC_SpotNotes__c, RICSC_ECard__c,
                                    RICSC_CollectionOfInterests__c, RICSC_ProductOfInterests__c,
                                    RICSC_Hobbies__c, RICSC_LocalVIP__c, RICSC_VIP__c, RICSC_FirstSalesDate__c,
                                    RICSC_LastSalesDate__c, RICSC_LastTransactionDate__c, RICSC_FirstTransactionDate__c,
                                    RICSC_LastPurchaseMarket__c, RICSC_LastPurchaseBoutique__c, RICSC_TotalNumberOfRepairs__c,
                                    RICSC_TotalNumberOfSales__c, RICSC_HighJeweleryTurnover__c, RICSC_HighJeweleryPieces__c,
                                    RICSC_HighestJeweleryTicket__c, RICSC_Turnover__c, RICSC_TransactionChannelsSelected__c, RICSC_HasLocalRecords__c FROM Account];
    System.debug('==> accounts: ' + accounts);
    for(Account acc : accounts){
      if(acc.RICSC_HasLocalRecords__c){
        System.assertEquals(acc.RICSC_Turnover__c, 3000, 'Error in calculating turnover');
        System.assertEquals(acc.RICSC_Notes__c, 'Some info about the customer', 'Error in calculating notes');
      }
    }
  }
}