@isTest
private class BatchConventionRateCalculation_Test {

  @testSetup
  static void setup() {

    Account newCartierPersonAccountGR = new Account();
    newCartierPersonAccountGR.FirstName = 'FirstNameGoldenRecord';
    newCartierPersonAccountGR.LastName = 'LastNameGoldenRecord';
    newCartierPersonAccountGR.RICSC_Maison__c = 'Cartier';
    newCartierPersonAccountGR.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier');
    newCartierPersonAccountGR.RICSC_IsGoldenRecord__c = true;
    newCartierPersonAccountGR.RICSC_HasLocalRecords__c = true;
    insert newCartierPersonAccountGR;

    Account newCartierPersonAccount = new Account();
    newCartierPersonAccount.FirstName = 'FirstNameLocalRecord';
    newCartierPersonAccount.LastName = 'LastNameLocalRecord';
    newCartierPersonAccount.RICSC_Maison__c = 'Cartier';
    newCartierPersonAccount.RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier');
    newCartierPersonAccount.RICSC_GoldenRecord__c = newCartierPersonAccountGR.Id;
    newCartierPersonAccount.RICSC_IsGoldenRecord__c = false;
    newCartierPersonAccount.RICSC_HasLocalRecords__c = false;
    insert newCartierPersonAccount;

    RICSC_Transaction__c testTransaction = new RICSC_Transaction__c(RICSC_Account__c = newCartierPersonAccount.Id,RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR', RICSC_Maison__c = 'Cartier');
    insert testTransaction;

    RICSC_Transaction__c testTransaction2 = new RICSC_Transaction__c(RICSC_Account__c = newCartierPersonAccount.Id,RICSC_AmountWithTax__c = 220000,RICSC_CurrencyKey__c = 'EUR', RICSC_Maison__c = 'Cartier');
    insert testTransaction2;
}

  static testmethod void conventionRateCalculationGoldenRecord() {
    Test.startTest();
    BatchConventionRateCalculation b = new BatchConventionRateCalculation(false, null);
    Id batchId = Database.executeBatch(b);
    Account accAfter = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE LastName = 'LastNameGoldenRecord'];
    Test.stopTest();
    System.assertEquals(220000, accAfter.RICSC_AverageBasket__c, 'Average basket assertion failed');
    System.assertEquals(440000, accAfter.RICSC_Turnover__c, 'Turnover assertion failed');
  }


  static testmethod void conventionRateCalculationLocalRecord() {
    Test.startTest();
    BatchConventionRateCalculation b = new BatchConventionRateCalculation(false, null);
    Id batchId = Database.executeBatch(b);
    Account accAfter = [SELECT Id,RICSC_Turnover__c,RICSC_AverageBasket__c FROM Account WHERE LastName = 'LastNameLocalRecord'];
    Test.stopTest();
    System.assertEquals(220000, accAfter.RICSC_AverageBasket__c, 'Average basket assertion failed');
    System.assert(accAfter.RICSC_Turnover__c!=null, 'Turnover should be caclulated on the local account');
  }
}