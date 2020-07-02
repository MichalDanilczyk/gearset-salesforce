/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on RICSC_Wishlist__c object used within the trigger framework.
******************************************************************************/

public with sharing class WishlistTriggerHandler {
  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of Wishlist based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_WishlistsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','WishlistTriggerHandler',td.newList);
    }
  }
}