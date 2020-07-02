@isTest
public with sharing class UserTriggerHandler_Test {

    @testSetup

    static void setup() {
        User u1 = UtilityTests.getuser('CAR CRM Manager');
        insert u1;
        User u2 =UtilityTests.getuser('System Administrator');
        insert u2;
    }

    static testmethod void changeUserasCRM(){
        Boolean result = false;
        Profile profid = [SELECT id FROM Profile WHERE Name = 'CAR CRM Manager' LIMIT 1];
        User u1 = [SELECT id,LanguageLocaleKey FROM User WHERE ProfileId =:profid.id LIMIT 1];
        System.runAs(u1) {
         // The following code runs as user u2.
         System.debug('Current User: ' + UserInfo.getUserName());
         System.debug('Current Profile: ' + UserInfo.getProfileId());
         u1.LanguageLocaleKey = 'fr';
         try{
          update u1;
         }
         catch (DmlException ex){
           result = true;
         }
         System.assert(result);
    }
    }

    static testmethod void changeUserasAdmin(){
        Boolean result = true;
        Profile profid = [SELECT id FROM Profile WHERE Name = 'System Administrator'];
        User u2 = [SELECT id,LanguageLocaleKey FROM User WHERE ProfileId =:profid.id AND isActive=true Limit 1];
        System.runAs(u2) {
         // The following code runs as user u2.
         System.debug('Current User: ' + UserInfo.getUserName());
         System.debug('Current Profile: ' + UserInfo.getProfileId());
         u2.LanguageLocaleKey = 'fr';
         try{
          update u2;
         }
         catch (DmlException ex){
           result = false;
         }
         System.assert(result);
    }
    }
}