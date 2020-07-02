/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on RICSC_SocialMediaID__c object used within the trigger framework.
******************************************************************************/

public with sharing class SocialMediaIDTriggerHandler {

  public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> accountIds = new Set<Id>();
      for(RICSC_SocialMediaID__c email : (List<RICSC_SocialMediaID__c>) td.newList){
        if(email.RICSC_Account__c != null){
          accountIds.add(email.RICSC_Account__c);
        }
        if(email.RICSC_GR__c != null){
          accountIds.add(email.RICSC_GR__c);
        }
      }

      if(td.isInsert){
        SharingRuleTriggerHelper.AfterInsert(td.newList,accountIds,'RICSC_SocialMediaID__share');
      }
      if(td.isUpdate){
        SharingRuleTriggerHelper.AfterUpdate(td.newList,td.oldMap,accountIds,'RICSC_SocialMediaID__share');
      }
    }
  }

  public without sharing class DefaultSocialMediaIDCheck implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> involvedAccs = new Set<Id>();

      if(td.isInsert){
        for(SObject currentRecord : (List<SObject>) td.newList){
          if(currentRecord.get('RICSC_GR__c') != null){
            involvedAccs.add(currentRecord.get('RICSC_GR__c').toString());
          }
        }
      }else if(td.isUpdate){
        for(SObject currentRecord : (List<SObject>) td.newList){
          if(currentRecord.get('RICSC_GR__c') != null){
            involvedAccs.add(currentRecord.get('RICSC_GR__c').toString());
          }
        }
      }
      if(involvedAccs.size()>0){
        if(!Utility.isAsync()){
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_SocialMediaID__c','RICSC_SocialMediaIDsGR__r',involvedAccs,'RICSC_DefaultSocialMediaID__c','RICSC_DefaultGRSocialMediaID__c'));
        }else{
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_SocialMediaID__c','RICSC_SocialMediaIDsGR__r',involvedAccs,'RICSC_DefaultSocialMediaID__c','RICSC_DefaultGRSocialMediaID__c');
        }
      }
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of SocialMedia based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_SocialMediaIDsAccount__r','RICSC_Account__c','RICSC_GR__c','SocialMediaIDTriggerHandler',td.newList);
    }
  }
}