/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on RICSC_Phone__c object used within the trigger framework.
******************************************************************************/

public with sharing class PhoneTriggerHandler {

    public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {
      public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

        Set<Id> accountIds = new Set<Id>();
        for(RICSC_Phone__c email : (List<RICSC_Phone__c>) td.newList){
          if(email.RICSC_Account__c != null){
            accountIds.add(email.RICSC_Account__c);
          }
          if(email.RICSC_GR__c != null){
            accountIds.add(email.RICSC_GR__c);
          }
        }

        if(td.isInsert){
          SharingRuleTriggerHelper.AfterInsert(td.newList,accountIds,'RICSC_Phone__share');
        }
        if(td.isUpdate){
          System.debug(accountIds);
          SharingRuleTriggerHelper.AfterUpdate(td.newList,td.oldMap,accountIds,'RICSC_Phone__share');
        }
      }
    }

    public without sharing class DefaultPhoneCheck implements TRG_TriggerHandlerInterface {
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
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Phone__c','RICSC_PhonesGR__r',involvedAccs,'RICSC_DefaultPhone__c','RICSC_DefaultGRPhone__c'));
        }else{
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Phone__c','RICSC_PhonesGR__r',involvedAccs,'RICSC_DefaultPhone__c','RICSC_DefaultGRPhone__c');
        }
      }
    }
  }
  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of phone based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_PhonesAccount__r','RICSC_Account__c','RICSC_GR__c','PhoneTriggerHandler',td.newList);
    }
  }
}