/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on Address object used within the trigger framework.
******************************************************************************/

public with sharing class AddressTriggerHandler {

  public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {
      public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

        Set<Id> accountIds = new Set<Id>();
        for(RICSC_Address__c email : (List<RICSC_Address__c>) td.newList){
          if(email.RICSC_Account__c != null){
            accountIds.add(email.RICSC_Account__c);
          }
          if(email.RICSC_GR__c != null){
            accountIds.add(email.RICSC_GR__c);
          }
        }

        if(td.isInsert){
          SharingRuleTriggerHelper.AfterInsert(td.newList,accountIds,'RICSC_Address__share');
        }
        if(td.isUpdate){
          SharingRuleTriggerHelper.AfterUpdate(td.newList,td.oldMap,accountIds,'RICSC_Address__share');
        }
      }
  }

  /******************************************************************************
  * @author       Silvan Sholla/Piergiorgio Lisanti
  * @date         15/Oct/2019
  * @description  This class contains trigger logic fired after addresses are inserted/modified/deleted.
  *               It computes RICSC_ResidentNonResident__c calculated field on Account records based on related transactions and addresses records.
  *               - Resident --> all transactions in the residency address
  *               - Non-Resident --> no transactions in the residency address
  *               - Traveller --> only part of transactions in the residency address
  ******************************************************************************/
  public without sharing class ResidencyFieldsOnAccount implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> accIds = new Set<Id>();
      Set<Id> accIdsGR = new Set<Id>();
      List<RICSC_Address__c> involvedAddresses = new List<RICSC_Address__c>();
      involvedAddresses = td.isDelete ? (List<RICSC_Address__c>) td.oldList : (List<RICSC_Address__c>) td.newList;
      for(RICSC_Address__c addr : involvedAddresses){
        if(td.isInsert){
          if(addr.RICSC_Country__c != null && addr.RICSC_AddressType__c == 'Residency'){
            if(addr.RICSC_Account__c != null){
              accIds.add(addr.RICSC_Account__c);
            }
            if(addr.RICSC_GR__c != null){
              accIdsGR.add(addr.RICSC_GR__c);
            }
          }
        } else if(td.isUpdate){
          if((addr.RICSC_Country__c != td.oldMap.get(addr.Id).get('RICSC_Country__c') ||
            addr.RICSC_Account__c != td.oldMap.get(addr.Id).get('RICSC_Account__c') ||
            addr.RICSC_AddressType__c != td.oldMap.get(addr.Id).get('RICSC_AddressType__c')) && addr.RICSC_Account__c != null){
              accIds.add(addr.RICSC_Account__c);
              if(addr.RICSC_Account__c != td.oldMap.get(addr.Id).get('RICSC_Account__c') && td.oldMap.get(addr.Id).get('RICSC_Account__c')!=null){
                accIds.add((Id)td.oldMap.get(addr.Id).get('RICSC_Account__c'));
              }
          }
          if((addr.RICSC_Country__c != td.oldMap.get(addr.Id).get('RICSC_Country__c') ||
            addr.RICSC_GR__c != td.oldMap.get(addr.Id).get('RICSC_GR__c') ||
            addr.RICSC_AddressType__c != td.oldMap.get(addr.Id).get('RICSC_AddressType__c')) && addr.RICSC_GR__c != null){

              accIdsGR.add(addr.RICSC_GR__c);
              if(addr.RICSC_GR__c != td.oldMap.get(addr.Id).get('RICSC_GR__c') && td.oldMap.get(addr.Id).get('RICSC_GR__c')!=null){
                accIds.add((Id) td.oldMap.get(addr.Id).get('RICSC_GR__c'));
              }
          }
        }else if(td.isDelete){
            if(addr.RICSC_Account__c != null && addr.RICSC_Country__c != null && addr.RICSC_AddressType__c == 'Residency'){
              accIds.add(addr.RICSC_Account__c);
            }
            if(addr.RICSC_GR__c != null && addr.RICSC_Country__c != null && addr.RICSC_AddressType__c == 'Residency'){
              accIdsGR.add(addr.RICSC_GR__c);
            }
        }
      }

      if(accIds.size()>0){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        update CalculatingFieldsHandler.computeResidenceNonResidence(accIds,'RICSC_Account__c',true);
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
      }
      if(accIdsGR.size()>0){
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
        update CalculatingFieldsHandler.computeResidenceNonResidence(accIdsGR,'RICSC_GR__c',true);
        TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
      }
    }
  }

  public without sharing class DefaultAddressCheck implements TRG_TriggerHandlerInterface {
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
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Address__c','RICSC_AddressesGR__r',involvedAccs,'RICSC_LRMainAddress__c','RICSC_GRMainAddress__c'));
        }else{
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Address__c','RICSC_AddressesGR__r',involvedAccs,'RICSC_LRMainAddress__c','RICSC_GRMainAddress__c');
        }
      }
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of address based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_AddressesAccount__r','RICSC_Account__c','RICSC_GR__c','AddressTriggerHandler',td.newList);
    }
  }
}