@isTest
public with sharing class BatchVCAReferenceMarketRegion_Test {

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

    Account transactionBoutique = UtilityTests.getBoutique();
    transactionBoutique.Name = 'Boutique';
    transactionBoutique.RICSC_CountryOfOrigin__c = 'France';
    transactionBoutique.RICSC_Maison__c = 'Cartier';
    insert transactionBoutique;

    Account newVanCleefAndArpelsGoldenRecord = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsGoldenRecord.LastName = 'VanCleefAndArpelsGoldenLocalAccount';
    newVanCleefAndArpelsGoldenRecord.RICSC_ReferenceBoutique__c = transactionBoutique.Id;
    insert newVanCleefAndArpelsGoldenRecord;
  }

  static testmethod void referenceMarketRegionChange() {

    Test.startTest();
    BatchVCAReferenceMarketRegion bc = new BatchVCAReferenceMarketRegion(true,null);
    Database.executeBatch(bc, 1000);
    Test.stopTest();

    Account acc = [SELECT RICSC_ReferenceMarket__c,RICSC_ReferenceRegion__c FROM Account WHERE LastName = 'VanCleefAndArpelsGoldenLocalAccount'];
    System.assertEquals('France', acc.RICSC_ReferenceMarket__c);
    System.assertEquals('Europe', acc.RICSC_ReferenceRegion__c);
  }
}