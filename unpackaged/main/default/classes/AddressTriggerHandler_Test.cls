@isTest
public with sharing class AddressTriggerHandler_Test {

@testSetup
  static void setup() {

    Contact newFrenchSalesAssociate = UtilityTests.getContact();
    newFrenchSalesAssociate.RICSC_CountryOfOrigin__c = 'France';
    insert newFrenchSalesAssociate;
    Contact newMonacoSalesAssociate = UtilityTests.getContact();
    newMonacoSalesAssociate.RICSC_CountryOfOrigin__c = 'Monaco';
    insert newMonacoSalesAssociate;

    Account newVanCleefAndArpelsAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsAccount.LastName = 'VanCleefAndArpelsFranceAccount';
    newVanCleefAndArpelsAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsAccount.RICSC_ReferenceSA__c = newFrenchSalesAssociate.Id;
    insert newVanCleefAndArpelsAccount;

    RICSC_Address__c afterUpdateTestingAddress = UtilityTests.getAddress();
    afterUpdateTestingAddress.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingAddress;

    Account newVanCleefAndArpelsMonacoAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsMonacoAccount.LastName = 'VanCleefAndArpelsMonacoAccount';
    newVanCleefAndArpelsMonacoAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsMonacoAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsMonacoAccount;

  }

  static testmethod void afterInsertSharingRulesCreateOnAddressObject() {
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    RICSC_Address__c testAddress = UtilityTests.getAddress();
    testAddress.RICSC_Account__c = vanCleefAndArpelsAccount.Id;
    insert testAddress;

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Address__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnAddressObject() {

    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Address__share)];
    System.assertEquals(gp.isEmpty(),true);

    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsMonacoAccount'];
    RICSC_Address__c updateAddress = [SELECT Id,RICSC_Account__c FROM RICSC_Address__c];
    updateAddress.RICSC_Account__c = acc.Id;
    update updateAddress;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Address__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

}