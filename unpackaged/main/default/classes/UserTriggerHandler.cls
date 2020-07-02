public with sharing class UserTriggerHandler {

    public without sharing class RestrictionLanguage implements TRG_TriggerHandlerInterface {
        public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
              for (Id uid : td.oldMap.keySet()){
               if(td.oldMap.get(uid).get('LanguageLocaleKey')!= td.newMap.get(uid).get('LanguageLocaleKey') && !Utility.hasAdminPrivileges){
                td.newMap.get(uid).addError('Language cannot be modified');
               }
              }
        }
    }
}