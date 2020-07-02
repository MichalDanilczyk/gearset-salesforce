@isTest
private class CalculatingFieldsHandler_Test {

  @testSetup
  static void setup() {

    RICSC_Localisation__c franceLocalisationRegion = new RICSC_Localisation__c();
    FranceLocalisationRegion.RICSC_LocalisationLevel__c = 'Region';
		FranceLocalisationRegion.Name = 'Europe';
	  FranceLocalisationRegion.RICSC_Maison__c = 'Cartier';
    insert FranceLocalisationRegion;

    RICSC_Localisation__c franceLocalisationMarket = new RICSC_Localisation__c();
    FranceLocalisationMarket.RICSC_LocalisationLevel__c = 'Market';
		FranceLocalisationMarket.Name = 'France';
		FranceLocalisationMarket.RICSC_ParentLocalisation__c = FranceLocalisationRegion.Id;
	  FranceLocalisationMarket.RICSC_Maison__c = 'Cartier';
    insert FranceLocalisationMarket;

    RICSC_Localisation__c franceLocalisation = new RICSC_Localisation__c();
    FranceLocalisation.RICSC_LocalisationLevel__c = 'Country';
		FranceLocalisation.Name = 'France';
		FranceLocalisation.RICSC_ParentLocalisation__c = FranceLocalisationMarket.Id;
	  FranceLocalisation.RICSC_Maison__c = 'Cartier';
    insert franceLocalisation;

    Contact newFrenchSalesAssociate = UtilityTests.getContact();
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    insert newFrenchSalesAssociate;

    Account transactionBoutique = UtilityTests.getBoutique();
    transactionBoutique.Name = 'TransactionBoutique';
    transactionBoutique.RICSC_CountryOfOrigin__c = 'France';
    transactionBoutique.RICSC_Maison__c = 'Cartier';
    insert transactionBoutique;

    Account referenceSABoutique = UtilityTests.getBoutique();
    referenceSABoutique.Name = 'ReferenceSABoutique';
    referenceSABoutique.RICSC_CountryOfOrigin__c = 'France';
    referenceSABoutique.RICSC_Maison__c = 'Cartier';
    insert referenceSABoutique;

    Contact newUSASalesAssociate = UtilityTests.getContact();
    newUSASalesAssociate.RICSC_CountryOfOrigin__c = 'USA';
    newUSASalesAssociate.AccountId = referenceSABoutique.Id;
    insert newUSASalesAssociate;

    Account newVanCleefAndArpelsGoldenRecord = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsGoldenRecord.LastName = 'VanCleefAndArpelsGoldenRecordAccount';
    newVanCleefAndArpelsGoldenRecord.RICSC_VIP__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 2;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 0;
    newVanCleefAndArpelsGoldenRecord.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsGoldenRecord;

    Account newVanCleefAndArpelsAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsLocalReordAccount';
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsAccount;

    newVanCleefAndArpelsAccount.RICSC_GoldenRecord__c = newVanCleefAndArpelsGoldenRecord.id;
    update newVanCleefAndArpelsAccount;

    RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_SalesAssociate__c = newUSASalesAssociate.Id,RICSC_Boutique__c = transactionBoutique.Id,RICSC_Account__c = newVanCleefAndArpelsAccount.Id,RICSC_Maison__c = 'Cartier',RICSC_TransactionCategory__c = 'Sale',RICSC_AmountWithTaxEUR__c = 260000,RICSC_CurrencyKey__c = 'EUR',RICSC_TransactionDate__c = Date.newInstance(2016, 12, 9),RICSC_CountryOfOrigin__c = 'Monaco');
    insert testTransaction;

  }

  static testmethod void vCAGoldenRecord() {

    //Before the insertion of the transaction the golden record reference SA is from France
    //After the transaction insert The Reference SA is going to be from USA , because
    //we entered a transaction and this automaticaly makes it as top 1 SA and top 1 Boutique

    Account goldenRecordAcc = [SELECT id,RICSC_Top1SA__c,RICSC_Top1Boutique__c,RICSC_ReferenceBoutique__c,RICSC_FirstSalesDate__c,
                                RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c,RICSC_ReferenceSA__r.AccountId,RICSC_LastSalesDate__c,
                                RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.Name,RICSC_HighJeweleryPieces__c,
                                RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.RICSC_ParentLocalisation__r.Name,
                                RICSC_ReferenceMarket__c,RICSC_ReferenceRegion__c,RICSC_LastTransactionDate__c,RICSC_LastPurchaseBoutique__c,RICSC_TotalNumberOfRepairs__c
                                FROM Account WHERE RICSC_IsGoldenRecord__c = true AND RICSC_HasLocalRecords__c = true];

    //-------------------------THE FOLLOWING ARE FOR GOLDEN RECORD------------------------------//

    //after the transaction insertion the reference sa changed based on the top 1 obutique
    System.assertEquals('USA', goldenRecordAcc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c);

    //reference SA in golden record equals to the top 1 SA
    System.assertEquals(goldenRecordAcc.RICSC_ReferenceSA__c,goldenRecordAcc.RICSC_Top1SA__c);

    //Top 1 boutique equals to the highest turnover boutique of the transactions (it was empty before the transaction insert)
    System.assertNotEquals(null,goldenRecordAcc.RICSC_Top1Boutique__c);

    //reference Boutique in VCA is Equal to the boutique of the reference SA
    System.assertEquals(goldenRecordAcc.RICSC_ReferenceBoutique__c,goldenRecordAcc.RICSC_ReferenceSA__r.AccountId);

    //reference market is the market from the reference SA
    System.assertEquals(goldenRecordAcc.RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.Name,goldenRecordAcc.RICSC_ReferenceMarket__c);

    //reference region is the region from the reference SA
    System.assertEquals(goldenRecordAcc.RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.RICSC_ParentLocalisation__r.Name,goldenRecordAcc.RICSC_ReferenceRegion__c);

    //First Sales Date
    System.assertEquals(goldenRecordAcc.RICSC_FirstSalesDate__c,Date.newInstance(2016, 12, 9));

    //Last Sales Date
    System.assertEquals(goldenRecordAcc.RICSC_LastSalesDate__c,Date.newInstance(2016, 12, 9));

    //Last Transaction Date
    System.assertEquals(goldenRecordAcc.RICSC_LastTransactionDate__c,Date.newInstance(2016, 12, 9));

    //Last Purchase Boutique
    System.assertEquals([SELECT Id FROM Account WHERE Name = 'TransactionBoutique'].Id,goldenRecordAcc.RICSC_LastPurchaseBoutique__c);

    //Total Number Of Repairs
    System.assertEquals(0,goldenRecordAcc.RICSC_TotalNumberOfRepairs__c);

    //High Jewelery Pieces
    System.assertEquals(0,goldenRecordAcc.RICSC_HighJeweleryPieces__c);

  }

  static testmethod void vCALocalRecord() {

    //Before the insertion of the transaction the golden record reference SA is from France
    //After the transaction insert The Reference SA is going to be from USA , because
    //we entered a transaction and this automaticaly makes it as top 1 SA and top 1 Boutique

    Account localRecordAcc = [SELECT id,RICSC_Top1SA__c,RICSC_Top1Boutique__c,RICSC_ReferenceBoutique__c,RICSC_LastPurchaseBoutique__c,RICSC_LastSalesDate__c,
                              RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c,RICSC_ReferenceSA__r.AccountId,RICSC_LastTransactionDate__c,
                              RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.Name,RICSC_FirstSalesDate__c,
                              RICSC_ReferenceSA__r.Account.RICSC_Localisation__r.RICSC_ParentLocalisation__r.RICSC_ParentLocalisation__r.Name,
                              RICSC_ReferenceMarket__c,RICSC_ReferenceRegion__c,RICSC_HighJeweleryPieces__c,RICSC_TotalNumberOfRepairs__c
                              FROM Account WHERE Name = 'VanCleefAndArpelsLocalReordAccount'];

    //-------------------------THE FOLLOWING ARE FOR LOCAL RECORD------------------------------//

    //after the transaction insertion the reference sa shouldnt changed based on the top 1 obutique
    System.assertNotEquals('USA', localRecordAcc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c);

    //reference SA in local record is not equal to the top 1 SA
    System.assertNotEquals(localRecordAcc.RICSC_ReferenceSA__c,localRecordAcc.RICSC_Top1SA__c);

    //Top 1 boutique doesnt get calculated on the local level
    System.assertEquals(null,localRecordAcc.RICSC_Top1Boutique__c);

    //reference Boutique isnt calculated on the local record
    System.assertEquals(null,localRecordAcc.RICSC_ReferenceBoutique__c);

    //reference market isnt calculated on the local record
    System.assertEquals(null,localRecordAcc.RICSC_ReferenceMarket__c);

    //reference region isnt calculated on the local record
    System.assertEquals(null,localRecordAcc.RICSC_ReferenceRegion__c);

    //First Sales Date - not calculated on local record
    System.assertEquals(null,localRecordAcc.RICSC_FirstSalesDate__c);

    //Last Sales Date
    System.assert(localRecordAcc.RICSC_LastSalesDate__c==null);

    //Last Transaction Date
    System.assertEquals(Date.newInstance(2016, 12, 9),localRecordAcc.RICSC_LastTransactionDate__c);

    //Last Purchase Boutique
    System.assertEquals([SELECT Id FROM Account WHERE Name = 'TransactionBoutique'].Id,localRecordAcc.RICSC_LastPurchaseBoutique__c);

    //Total Number Of Repairs - not calculated on local record
    System.assertEquals(null,localRecordAcc.RICSC_TotalNumberOfRepairs__c);

    //High Jewelery Pieces
    System.assertEquals(0,localRecordAcc.RICSC_HighJeweleryPieces__c);

  }

}