global class DirectProcessingExtension implements dupcheck.dc3PluginInterface {

    private static Set<String> implementedEvents = new Set<String>{'DIRECT_PROCESS_BEFORE'};

    global Boolean isAvailable(dupcheck.dc3Plugin.PluginEventType eventType) {
        return DirectProcessingExtension.implementedEvents.contains(eventType.name());
    }

    global Object execute(dupcheck.dc3Plugin.PluginEventType eventType, Object eventData) {
      switch on eventType {
        when DIRECT_PROCESS_BEFORE {
            return this.directProcessBefore((dupcheck.dc3PluginModel.DirectProcessBeforeInput) eventData);
        }
        when else {
            return null;
        }
      }
	  }

    global dupcheck.dc3PluginModel.DirectProcessBeforeOutput directProcessBefore(dupcheck.dc3PluginModel.DirectProcessBeforeInput input) {
      // execute some custom logic based on the input values.
      Map<String,List<dupcheck.dc3SearchResult>> inputResults = input.searchResults;
      if(inputResults.containsKey('001P')){
        Map<String, MaisonsConfiguration__mdt> maisonToMdt = Utility.getMaisonConfigurationMap();
        Map<String, SObject> mapIdToRecordType = Utility.getMap(RecordTypeHelper.getRTList('Account'), 'Id');
        Map<String,List<dupcheck.dc3SearchResult>> outputResults = new Map<String,List<dupcheck.dc3SearchResult>>();
        List<dupcheck.dc3SearchResult> outputResultsList = new List<dupcheck.dc3SearchResult>();
        Set<Id> accountsIds = new Set<Id>();
        for(dupcheck.dc3SearchResult sr : inputResults.get('001P')){
          accountsIds.add((Id)sr.objectData.get('Id'));
        }
        Map<Id, Account> accountsInResults = new Map<Id,Account>([SELECT Id, RecordType.DeveloperName, RICSC_Turnover__c
                                            FROM Account
                                            WHERE Id IN :accountsIds]);
        for(dupcheck.dc3SearchResult sr : inputResults.get('001P')){
          Account acc = accountsInResults.get((Id)sr.objectData.get('Id'));
          MaisonsConfiguration__mdt maisonConfiguration = maisonToMdt.get(acc.RecordType.DeveloperName);
          if(sr.score > maisonConfiguration.DirectProcessingScoreThreshold__c &&
              (acc.RICSC_Turnover__c == null || acc.RICSC_Turnover__c < maisonConfiguration.DirectProcessingTurnoverThreshold__c)){
            outputResultsList.add(sr);
          }
          else if(acc.RICSC_Turnover__c != null && acc.RICSC_Turnover__c >= maisonConfiguration.DirectProcessingTurnoverThreshold__c){
            outputResults.put('001P', new List<dupcheck.dc3SearchResult>());
            input.searchResults = outputResults;
            dupcheck.dc3PluginModel.DirectProcessBeforeOutput output = new dupcheck.dc3PluginModel.DirectProcessBeforeOutput(input);
            return output;
          }
        }
        outputResults.put('001P', outputResultsList);
        input.searchResults = outputResults;
      }
      // built the output and tell DC Direct Processing how to continue.
      dupcheck.dc3PluginModel.DirectProcessBeforeOutput output = new dupcheck.dc3PluginModel.DirectProcessBeforeOutput(input);
      output.doMerge = true;
      return output;
    }
}