@isTest
public with sharing class SocialMediaIDTriggerHandler_Test {

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

    RICSC_SocialMediaID__c afterUpdateTestingSocialMediaID = UtilityTests.getSocialMediaID();
    afterUpdateTestingSocialMediaID.RICSC_Account__c = newVanCleefAndArpelsAccount.Id;
    insert afterUpdateTestingSocialMediaID;

    Account newVanCleefAndArpelsMonacoAccount = UtilityTests.getPersonAccount();
    newVanCleefAndArpelsMonacoAccount.LastName = 'VanCleefAndArpelsMonacoAccount';
    newVanCleefAndArpelsMonacoAccount.RICSC_VIP__c = true;
    newVanCleefAndArpelsMonacoAccount.RICSC_ReferenceSA__c = newMonacoSalesAssociate.Id;
    insert newVanCleefAndArpelsMonacoAccount;

  }

  static testmethod void afterInsertSharingRulesCreateOnSocialMediaIDObject() {
    Contact frenchAccount = [SELECT Id FROM Contact WHERE RICSC_CountryOfOrigin__c = 'France' LIMIT 1];
    Account vanCleefAndArpelsAccount = [SELECT Id, RICSC_VIP__c, RICSC_ReferenceSA__c FROM Account WHERE Name = 'VanCleefAndArpelsFranceAccount'];
    RICSC_SocialMediaID__c testSocialMediaID = UtilityTests.getSocialMediaID();
    testSocialMediaID.RICSC_Account__c = vanCleefAndArpelsAccount.Id;
    insert testSocialMediaID;

    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMFrance' AND Id IN (SELECT UserOrGroupId FROM RICSC_SocialMediaID__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

  static testmethod void afterUpdateSharingRulesCreateOnSocialMediaIDObject() {

    //BeforeUpdate
    List<Group> gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_SocialMediaID__share)];
    System.assertEquals(gp.isEmpty(),true);

    Account acc = [SELECT Id FROM Account WHERE Name = 'VanCleefAndArpelsMonacoAccount'];
    RICSC_SocialMediaID__c updateSocialMediaID = [SELECT Id,RICSC_Account__c FROM RICSC_SocialMediaID__c];
    updateSocialMediaID.RICSC_Account__c = acc.Id;
    update updateSocialMediaID;

    //AfterUpdate
    gp = [SELECT DeveloperName FROM Group WHERE DeveloperName = 'RICSC_VCACRMMonaco' AND Id IN (SELECT UserOrGroupId FROM RICSC_SocialMediaID__share)];
    System.assertEquals(gp.isEmpty(),false);
  }

}