@isTest
private class BatchResidenceNonResidence_Test {

  @testSetup
  static void setup() {
    UtilityTests.testSetup();
    List<Account> accounts = UtilityTests.getAccounts(3);
    insert accounts;

    List<RICSC_Address__c> addressList = new List<RICSC_Address__c>();
    List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
    Account acc = accounts.get(0);
    RICSC_Address__c address = UtilityTests.getAddress();
    address.RICSC_AddressType__c = 'Residency';
    address.RICSC_Country__c = 'Italy';
    address.RICSC_Account__c = acc.Id;
    addressList.add(address);

    RICSC_Transaction__c t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Italy';
    transactionsList.add(t);

    acc = accounts.get(1);
    address = UtilityTests.getAddress();
    address.RICSC_AddressType__c = 'Residency';
    address.RICSC_Country__c = 'Italy';
    address.RICSC_Account__c = acc.Id;
    addressList.add(address);

    t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Uganda';
    transactionsList.add(t);

    acc = accounts.get(2);
    address = UtilityTests.getAddress();
    address.RICSC_AddressType__c = 'Residency';
    address.RICSC_Country__c = 'Italy';
    address.RICSC_Account__c = acc.Id;
    addressList.add(address);

    t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Uganda';
    transactionsList.add(t);
    t = UtilityTests.getTransaction();
    t.RICSC_Account__c = acc.Id;
    t.RICSC_CountryOfOrigin__c = 'Italy';
    transactionsList.add(t);

    insert addressList;
    insert transactionsList;
}

  static testmethod void calculateResidenceNonResidence() {
    Test.startTest();
    BatchResidenceNonResidence b = new BatchResidenceNonResidence(false,null);
    Id batchId = Database.executeBatch(b);
    List<Account> accounts = [SELECT Id, RICSC_ResidentNonResident__c FROM Account];
    Test.stopTest();
    List<Account> residentAccounts = new List<Account>();
    List<Account> nonResidentAccounts = new List<Account>();
    List<Account> travellerAccounts = new List<Account>();
    for(Account acc : accounts){
      if(acc.RICSC_ResidentNonResident__c.equals('Resident')){
        residentAccounts.add(acc);
      }
      else if (acc.RICSC_ResidentNonResident__c.equals('Non-Resident')){
        nonResidentAccounts.add(acc);
      }
      else if (acc.RICSC_ResidentNonResident__c.equals('Traveller')){
        travellerAccounts.add(acc);
      }
    }
    System.assert(residentAccounts.size()==1, 'Assertion failed on resident accounts');
    System.assert(nonResidentAccounts.size()==1, 'Assertion failed on non-resident accounts');
    System.assert(travellerAccounts.size()==1, 'Assertion failed on traveller accounts');
  }
}