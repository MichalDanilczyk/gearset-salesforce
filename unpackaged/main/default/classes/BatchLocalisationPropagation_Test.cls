@isTest
private class BatchLocalisationPropagation_Test {
    @testSetup
    static void setup() {

      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      List<RICSC_Localisation__c> locList = new List<RICSC_Localisation__c>();
      RICSC_Localisation__c localisationFrance = new RICSC_Localisation__c(Name = 'France',RICSC_LocalisationLevel__c = 'Country',RICSC_Maison__c = 'Cartier');
      locList.add(localisationFrance);
      insert locList;

      Account newBoutique = UtilityTests.getBoutique();
      newBoutique.RICSC_CountryOfOrigin__c = 'France';
      newBoutique.Name = 'France Boutiquea';
      newBoutique.RICSC_Maison__c = 'Cartier';
      insert newBoutique;


    }

    static testmethod void test() {
      Test.startTest();
      BatchLocalisationPropagation uca = new BatchLocalisationPropagation(true, null);
      Id batchId = Database.executeBatch(uca);
      Test.stopTest();
      System.assertEquals(Utility.getLocalisationId('Cartier','France'),[SELECT RICSC_Localisation__c FROM Account WHERE Name = 'France Boutiquea' LIMIT 1].RICSC_Localisation__c, 'Localisation non populated correctly');
    }



}