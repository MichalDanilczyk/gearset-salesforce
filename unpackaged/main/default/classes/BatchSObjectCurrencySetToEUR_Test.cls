@isTest
private class BatchSObjectCurrencySetToEUR_Test {

  @testSetup
  static void setup() {

    Account newVanCleefAndArpelsGoldenRecord = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsGoldenRecord.LastName = 'VanCleefAndArpelsGoldenRecordAccount';
    newVanCleefAndArpelsGoldenRecord.RICSC_VIP__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_HasLocalRecords__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_IsGoldenRecord__c = true;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 2;
    newVanCleefAndArpelsGoldenRecord.RICSC_TotalNumberOfRepairs__c = 0;
    newVanCleefAndArpelsGoldenRecord.CurrencyIsoCode = 'CHF';
    insert newVanCleefAndArpelsGoldenRecord;

    Account newVanCleefAndArpelsAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsLocalReordAccount';
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.CurrencyIsoCode = 'CHF';
    newVanCleefAndArpelsAccount.RICSC_IsGoldenRecord__c = false;
    newVanCleefAndArpelsAccount.RICSC_GoldenRecord__c = newVanCleefAndArpelsGoldenRecord.id;
    insert newVanCleefAndArpelsAccount;
  }

  static testmethod void currencyChangeFromCHFToEUR() {

    Account accGR = [SELECT CurrencyIsoCode FROM Account WHERE Name = 'VanCleefAndArpelsGoldenRecordAccount'];
    Account accLR = [SELECT CurrencyIsoCode FROM Account WHERE Name = 'VanCleefAndArpelsLocalReordAccount'];

    System.assertEquals(accGR.CurrencyIsoCode,'CHF');
    System.assertEquals(accLR.CurrencyIsoCode,'CHF');

    Test.startTest();
    BatchSObjectCurrencySetToEUR bas = new BatchSObjectCurrencySetToEUR(true,'SELECT CurrencyIsoCode FROM Account');
    Id batchId = Database.executeBatch(bas);
    Test.stopTest();

    Account accGRAfter = [SELECT CurrencyIsoCode FROM Account WHERE Name = 'VanCleefAndArpelsGoldenRecordAccount'];
    Account accLRAfter = [SELECT CurrencyIsoCode FROM Account WHERE Name = 'VanCleefAndArpelsLocalReordAccount'];

    System.assertEquals(accGRAfter.CurrencyIsoCode,'EUR');
    System.assertEquals(accLRAfter.CurrencyIsoCode,'EUR');

  }

}