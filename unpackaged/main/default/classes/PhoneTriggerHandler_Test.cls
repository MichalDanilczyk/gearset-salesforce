@isTest
public with sharing class PhoneTriggerHandler_Test {

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

    RICSC_Phone__c afterUpdateTestingPhone = UtilityTests.getPhone();
    afterUpdateTestingPhone.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingPhone;

    Account newVanCleefAndArpelsMonacoAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsMonacoAccount.LastName = 'VanCleefAndArpelsMonacoAccount';
    newVanCleefAndArpelsMonacoAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsMonacoAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsMonacoAccount;

  }

  static testmethod void afterInsertSharingRulesCreateOnPhoneObject() {
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    RICSC_Phone__c testPhone = UtilityTests.getPhone();
    testPhone.RICSC_Account__c = vanCleefAndArpelsAccount.Id;
    insert testPhone;

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_Phone__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnPhoneObject() {

    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Phone__share)];
    System.assertEquals(gp.isEmpty(),true);

    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsMonacoAccount'];
    RICSC_Phone__c updatePhone = [SELECT Id,RICSC_Account__c FROM RICSC_Phone__c];
    updatePhone.RICSC_Account__c = acc.Id;
    update updatePhone;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_Phone__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

}