@isTest
private class BatchCalculateGlobalSegment_Test {

  @testSetup
  static void setup() {

    Account newCartierPersonAccount = new Account();
    newCartierPersonAccount.FirstName = 'FirstName';
    newCartierPersonAccount.LastName = 'LastName';
    newCartierPersonAccount.RICSC_Maison__c = 'Cartier';
    newCartierPersonAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier');

    insert newCartierPersonAccount;

    RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_Account__c = newCartierPersonAccount.Id,RICSC_AmountWithTax__c = 220000,RICSC_AmountWithTaxEUR__c = 220000,RICSC_CountryOfOrigin__c = 'Monaco');
    insert testTransaction;

    Account newCartierPersonAccount2 = new Account();
    newCartierPersonAccount2.FirstName = 'FirstName2';
    newCartierPersonAccount2.LastName = 'LastName2';
    newCartierPersonAccount2.RICSC_Maison__c = 'Cartier';
    newCartierPersonAccount2.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier');

    insert newCartierPersonAccount2;

    RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = newCartierPersonAccount2.Id,RICSC_AmountWithTax__c = 220000,RICSC_AmountWithTaxEUR__c = 220000,RICSC_CountryOfOrigin__c = 'France');
    insert testTransaction2;

    newCartierPersonAccount2.RICSC_GoldenRecord__c = newCartierPersonAccount.Id;
    update newCartierPersonAccount2;
}

  static testmethod void calculateGlobalSegment() {
    Test.startTest();
    BatchCalculateGlobalSegment b = new BatchCalculateGlobalSegment(false, null);
    b.skipTriggersOnAccount = true;
    Id batchId = Database.executeBatch(b);
    Test.stopTest();
  }
}