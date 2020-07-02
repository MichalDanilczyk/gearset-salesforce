/****************************************************************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/Aug/2019
* @description  General Utility class used to store common methods used throughout the codebase
*****************************************************************************************************************************/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
public without sharing class Utility {


    /****************************************************************************************************************************
    * @description  Lazy loaded variable to store the current user data
    *****************************************************************************************************************************/
    @TestVisible
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static User myUser {
        get{

            if(myUser == null){

                String userID = UserInfo.getUserId();

                myUser = ((User)Database.query('SELECT ' + Utility.getFieldSetAsString(Schema.SObjectType.User.fieldSets.MyUser_Fields) +
                            ' FROM User WHERE Id = :userID')[0]);
            }
            return myUser;
        }
        private set;
    }


    /****************************************************************************************************************************
    * @description  Lazy loaded variable to store if the current user has admin privileges
    *****************************************************************************************************************************/
    @TestVisible
    public static Boolean hasAdminPrivileges {
        get{

            if(hasAdminPrivileges == null){
                hasAdminPrivileges = FeatureManagement.checkPermission('Admin');
            }

            return hasAdminPrivileges;

        }  private set;
    }

    /****************************************************************************************************************************
    * @description  Lazy loaded variable to store if the current user has Integration privileges
    *****************************************************************************************************************************/
    @TestVisible
    public static Boolean hasIntegrationPrivileges {
        get{

            if(hasIntegrationPrivileges == null){
                hasIntegrationPrivileges = FeatureManagement.checkPermission('Integration');
            }

            return hasIntegrationPrivileges;

        } private set;
    }


    /* GENERIC UTILITY METHODS - START */

    /********************************************************************************************************
    * @description      see getMap overload below
    * @param inputList  list of Sobject to transform into a map
    * @param key        field API name to use as key of output map
    * @return           a map composed of objects in input with specified key
    ********************************************************************************************************/
    public static Map<String,SObject> getMap(List<SObject> inputList, String key){
        return getMap(inputList, new List<String>{key}, new List<String>());
    }

    /********************************************************************************************************
    * @description      Returns a Map created from an input Sobject List with the dynamic keys specified
    *                   NOTE: key specified must correspond to a field with type String
    * @param inputList  list of Sobject to transform into a map
    * @param keys       list of field API names to use as key of output map
    * @param separators list of field separators to use when joining multiple key fields
    * @return           a map composed of objects in input with specified key
    ********************************************************************************************************/
    public static Map<String,SObject> getMap(List<SObject> inputList, List<String> keys, List<String> separators){

        Map<String,SObject> returnMap = new Map<String,SObject>();

        if(inputList == null || inputList.size() == 0 ){ return returnMap; }

        String concatenatedKey;

        for(SObject o : inputList){

            concatenatedKey = '';

            for(Integer i = 0; i<keys.size()-1; i++){
                concatenatedKey += String.valueOf(o.get(keys[i]) + separators[i]);
            }

            concatenatedKey += String.valueOf(o.get(keys[keys.size()-1]));

            returnMap.put(concatenatedKey,o);

        }

        return returnMap;
    }

    /********************************************************************************************************
    * @description      see getMap overload below
    * @param inputList  list of Sobject to transform into a map
    * @param key        field API name to use as key of output map
    * @return           a map composed of objects in input with specified key
    ********************************************************************************************************/
    public static Map<String,AggregateResult> getMap(List<AggregateResult> inputList, String key){
        return getMap(inputList, new List<String>{key}, new List<String>());
    }

    /********************************************************************************************************
    * @description      Returns a Map created from an input AggregateResult List with the dynamic keys specified
    *                   NOTE: key specified must correspond to a field with type String
    * @param inputList  list of Sobject to transform into a map
    * @param keys       list of field API names to use as key of output map
    * @param separators list of field separators to use when joining multiple key fields
    * @return           a map composed of objects in input with specified key
    ********************************************************************************************************/
    public static Map<String,AggregateResult> getMap(List<AggregateResult> inputList, List<String> keys, List<String> separators){

        Map<String,AggregateResult> returnMap = new Map<String,AggregateResult>();

        if(inputList == null || inputList.size() == 0 ){ return returnMap; }

        String concatenatedKey;

        for(AggregateResult o : inputList){

            concatenatedKey = '';

            for(Integer i = 0; i<keys.size()-1; i++){
                concatenatedKey += String.valueOf(o.get(keys[i]) + separators[i]);
            }

            concatenatedKey += String.valueOf(o.get(keys[keys.size()-1]));

            returnMap.put(concatenatedKey,o);

        }

        return returnMap;
    }


    /**********************************************************************************************
    * @description      Returns a Set of Ids of the SObjects in input
    * @param inputList  list of Sobject to transform into a set
    * @param idField    field API name to use as key of output set
    * @return           a set composed of Ids from list input for field specified
    **********************************************************************************************/
    public static Set<Id> getSetOfIds(List<SObject> inputList, String idField){

        Set<Id> returnSet = new Set<Id>();

        if(inputList == null || inputList.size() == 0 ){ return returnSet; }

        for(SObject o : inputList){

            returnSet.add((Id)o.get(idField));

        }

        return returnSet;

    }

    /**********************************************************************************************
    * @description      Returns a String with concatenated fieldSet Members separated by comma
    * @param fieldSet   fieldSet to stringify
    * @return           a String with concatenated fields
    **********************************************************************************************/
    public static String getFieldSetAsString(Schema.FieldSet fieldSet){
        return getFieldSetAsString(fieldSet, '');
	}

	/**********************************************************************************************
    * @description                  Returns a String with fieldSet Members separated by comma
    *                               with prepended the releationship string (terminated by a '.')
    * @param fieldSet               fieldSet to stringify
    * @param relationshipPrefix     the prefix (terminated by a '.') to prepend to each field
    * @return                       a String with concatenated fields
    **********************************************************************************************/
    public static String getFieldSetAsString(Schema.FieldSet fieldSet, String relationshipPrefix){

        String returnString = '';
        String relationshipPrefixEscaped = String.escapeSingleQuotes(relationshipPrefix);

        if(fieldSet == null){ return returnString; }

        for(Schema.FieldSetMember fm : fieldSet.getFields()){

            returnString += relationshipPrefixEscaped + fm.getFieldPath() + ', ';

        }

        return returnString.substringBeforeLast(', ');
    }

    /**********************************************************************************************
    * @description          Adds child Sobject to outputMap Map using keyField as key
    *                       Note: keyField must correspond to a String field
    * @param child          child object to add to the map
    * @param keyField       field used as map key
    * @param outputMap      the output map to populate
    **********************************************************************************************/
    public static void addToMapByKey(SObject child, Schema.SObjectField keyField, Map<String,List<SObject>> outputMap){

        if(child.get(keyField) != null){

            if(!outputMap.containsKey((String)child.get(keyField))){

                outputMap.put((String)child.get(keyField),new List<SObject>());

            }

            outputMap.get((String)child.get(keyField)).add(child);
        }

    }

    /**********************************************************************************************
    * @description          Adds child Sobject to outputMap Map using keyField
    *                       to generate the keyObject used in the map
    *                       Note: keyField must correspond to a String field
    * @param child          child object to add to the map
    * @param keyField       field used as map object Id value
    * @param outputMap      the output map to populate
    * @param objectType     the type of object as key of the map
    **********************************************************************************************/
    public static void addToMapByKey(SObject child, Schema.SObjectField keyField, Map<Sobject,List<SObject>> outputMap, Type objectType){

        if(child.get(keyField) != null){

            SObject curParent = (Sobject)objectType.newInstance();
            curParent.put('Id', (String)child.get(keyField));

            if(!outputMap.containsKey(curParent)){

                outputMap.put(curParent,new List<Sobject>());

            }

            outputMap.get(curParent).add(child);
        }

    }

    /**********************************************************************************************
    * @description          Extends a string representing a JSON object a key value pair
    * @param jsonObject     the input JSON object String to extend
    * @param key            the key to add to the JSON
    * @param value          the value to add to the JSON
    * @return               a String representing a JSON with the additional key,value pair
    **********************************************************************************************/
    public static String extendJSONObject(String jsonObject, String key, Object value){
        if(String.isBlank(jsonObject)){ return null; }
        return jsonObject.left(jsonObject.length() - 1) +',"'+key+'":'+JSON.serialize(value)+'}';
    }

    /* GENERIC UTILITY METHODS - END*/



    /* STATIC RESOURCES MGM - START */

    /**********************************************************************************************
    * @description                  Reads a Static Resource containing a json of records
    *                               and return the json object
    * @param staticResourceName     the value to add to the JSON
    * @return                       the Static Resource content
    **********************************************************************************************/
    public static String staticResourceToJsonObject(String staticResourceName){

        final String UTF8_BOM = '\uFEFF';

        StaticResource sr = [SELECT body, name FROM StaticResource WHERE Name = :staticResourceName LIMIT 1][0];

        return sr.body.toString().replace(UTF8_BOM, '');

    }

    /**********************************************************************************************
    * @description  Reads a Static Resource containing a csv of records and transforms it into
    *               a list of SObjects
    *               The Static Resource name must respect the following format:
    *               Configuration_OBJECTAPINAME
    *               where OBJECTAPINAME is the object API name where all occurrences of '__' have
    *               been substituted with '_'
    * @param objectAPIName     the object API name to compute path of the static resource
    * @return                  the list of Sobject from the csv static resource
    **********************************************************************************************/
    public static List<SObject> staticResourceCSVToListOfSobject( String objectAPIName){

        final String UTF8_BOM = '\uFEFF';
        List<String> rows;
        List<String> firstLine = new List<String>();
        Boolean fl = false;
        Integer line = 0;
        List<Sobject> objectList = new List<Sobject>();
        Boolean isRollupHelperConf = objectAPIName.equalsIgnoreCase('rh2__PS_Export_Rollups__c') ? true : false;
        String separator = isRollupHelperConf ? ';' : ',';

        String staticResourceName = 'Configuration_' + objectAPIName.replaceAll('__', '_');
        system.debug('SR name: ' + staticResourceName);
        StaticResource sr = [SELECT body, name FROM StaticResource WHERE Name = :staticResourceName LIMIT 1][0];

        String doc = sr.body.toString().replace(UTF8_BOM, '');
        rows = doc.split('\n');

        Schema.DescribeSObjectResult objectDescribeResult = Schema.getGlobalDescribe().get(objectAPIName).getDescribe();
        Map<String, Schema.SObjectField> objectFieldMap = objectDescribeResult.fields.getMap();

        for(String row : rows){
            line++;
            if(!fl){
                firstLine = row.split(separator);
                fl = true;
                continue;
            }

            List<String> currentLine = new List<String>();
            currentLine = row.split(separator);
            if(!isRollupHelperConf){
                System.assertEquals(currentLine.size(), firstLine.size(), 'The current row doesn\'t match with the header row. StaticResource: '+sr.name+', line: '+ line);
            }

            Sobject tmpObj = (Sobject)Type.forName(objectAPIName).newInstance();

            for(integer i = 0; i<currentLine.size(); i++){
                String field = isRollupHelperConf ? 'rh2__' + firstLine[i].trim() : firstLine[i].replace('"', '').trim();
                String value;
                if(isRollupHelperConf && i==1){
                    value = currentLine[i].replace('""', '"');
                    value = value.mid(1,value.length()-1);
                } else {
                    value = currentLine[i].replace('"', '').trim();
                }

                if(field.startsWith('RECORDTYPE.')){
                    tmpObj.put('recordtypeId',  RecordTypeHelper.getRTID(objectAPIName,value));
                }else if(objectFieldMap.get(field) == null && field.contains('.')){
                    //parent object
                    Schema.SObjectType parentObject = objectFieldMap.get(field.substringBefore('r.')+'c').getDescribe().getReferenceTo()[0];

                    tmpObj.putSobject(field.substringBefore('.'), parentObject.newSObject());
                    ((SObject)tmpObj.getSobject(field.substringBefore('.'))).put(field.substringAfter('.'), value);
                }
                else if(objectFieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Date){

                    if(value != ''){ tmpObj.put(field, Date.valueOf(value)); }
                    else{ tmpObj.put(field, null); }

                }
                else if(objectFieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Boolean ||
                        objectFieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Combobox) {

                    tmpObj.put(field, Boolean.valueOf(value));
                }
                else if(objectFieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Currency ||
                        objectFieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Double) {

                    tmpObj.put(field, Decimal.valueOf(value));
                }
                else{
                    tmpObj.put(field, value);
                }
            }
			//system.debug(tmpObj);
            objectList.add(tmpObj);
        }


        return objectList;

    }

    /* STATIC RESOURCES MGM - END */

    public static Map < String, Id > getGroupIdByDeveloperName() {
        Map < String, Id > groupIdByDeveloperName = new Map < String, Id > ();
        for (Group grp: [Select Id, DeveloperName From Group where Type = 'Role']){
            groupIdByDeveloperName.put(grp.DeveloperName, grp.Id);
        }
        return groupIdByDeveloperName;
    }

    public static Boolean isUnique(List<sObject> listOfSobject,SObject currentSobject){
      for(SObject temp : listOfSobject){
        if(temp == currentSobject){
          return false;
        }
      }
      return true;
    }

    public static Map < String, String > getRoleByCountryName() {
        Map < String, String > getRoleByCountryName = new Map < String, String > ();
        for (RICSC_VCACountryRole__mdt cmtd: [SELECT RICSC_RoleName__c,RICSC_CountryOfOrigin__c FROM RICSC_VCACountryRole__mdt]){
            getRoleByCountryName.put(cmtd.RICSC_CountryOfOrigin__c, cmtd.RICSC_RoleName__c);
        }
        return getRoleByCountryName;
    }

    public static List<GlobalSegmentConfTable__mdt> getGlobalSegmentConfTable(){
      List<GlobalSegmentConfTable__mdt> gsct = [SELECT FirstSaleFrom__c, FirstSaleTo__c, Flag__c, FrequencyFrom__c, FrequencyTo__c, HighestTurnover__c,
                                                        Maison__c, Order__c, Potential__c, PPFrequencyFrom__c, PPFrequencyTo__c, PPRecencyFrom__c, PPRecencyTo__c,
                                                        PPTurnoverFrom__c, PPTurnoverTo__c, ProductParameterToInclude__c, ProductParameterToExclude__c,
                                                        RangeForTotalTurnoverFrom__c, RangeForTotalTurnoverTo__c, RecencyFrom__c, RecencyTo__c,
                                                        RangeTurnoverFrom__c, RangeTurnoverTo__c, Segment__c, TurnoverAllTimeFrom__c, TurnoverAllTimeTo__c
                                                        FROM GlobalSegmentConfTable__mdt ORDER BY Maison__c, Order__c];
      return gsct;
    }

    public static List < DatedConversionRate > currencyConventionsToCorporateDatedExchangeRates(Set<String> isoCodes) {
      List<DatedConversionRate> currencies = [SELECT ConversionRate, IsoCode, StartDate, NextStartDate FROM DatedConversionRate WHERE IsoCode IN :isoCodes];
      return currencies;
    }

    public static Map < String, CurrencyType > currencyConventionsToCorporateCurrencyType(Set<String> isoCodes) {
      Map<String ,CurrencyType> conversions = new Map <String ,CurrencyType>();
      List<CurrencyType> currencies = new List<CurrencyType>();
      if (Schema.sObjectType.CurrencyType.isAccessible()) {
        currencies = [SELECT ConversionRate, IsoCode, isActive FROM CurrencyType WHERE IsActive = true AND IsoCode IN :isoCodes];
      }
      for (CurrencyType cur : currencies) {
        conversions.put(cur.IsoCode, cur);
      }
      return conversions;
    }

    /*************************************************************************************************
    * @author                       Maurizio D'Antonio
    * @date                         12/Nov/2019
    * @description                  Returns a dynamic SOQL statement for the whole object,
                                    includes the specified set of field.
    * @param objectName             Name of the object to get the fields from
    * @param whereClause            The WHERE condition to query
    * @param additionalFields       Additional fields to query
    * @param fieldsFilter           Which set of fields is needed to build the dybamic SOQL
    * @return                       Dynamic SOQL statement
    ***************************************************************************************************/


    public static string getSOQLWithFieldsFilter(String objectName, String whereClause, String additionalFields, UtilityConstants.SOQLFieldsFilter fieldsFilter){

        if (whereClause == null || whereClause == ''){ return null; }
        List<String> selectFields = new List<String>();

        switch on fieldsFilter {
          when ALL {
            selectFields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
          }
          when CREATABLE {
            // Get a map of field name and field token
            Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
            if (fMap != null){
                for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                    Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                    if (fd.isCreateable() && fd.getName()!='Name'){ // field is creatable exclude the Name field
                        selectFields.add(fd.getName());
                    }
                }
            }
          }
          when GOLDENRECORD {
            List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.FieldsToCopyOnGR.getFields();
            for(Schema.FieldSetMember m : fields){
              selectFields.add(m.getFieldPath());
            }
          }
        }

        if(additionalFields == null || additionalFields.equals('')){
          return 'SELECT ' + String.join(selectFields, ',') + ' FROM ' + objectName + ' WHERE ' + whereClause;
        }
        else{
          return 'SELECT ' + String.join(selectFields, ',') + ',' + additionalFields + ' FROM ' + objectName + ' WHERE ' + whereClause;
        }
    }

    /**********************************************************************************************
    * @author                 Maurizio D'Antonio
    * @date                   15/Oct/2019
    * @description            Method used when we need to execute a DML involving different types of object
    * @param type2Records     Map containing the object type as key and list of related object as values
    * @param record           Record to be added to the map
    **********************************************************************************************/
    public static void addRecordToMap(Map<SObjectType, List<SObject>> type2Records, SObject record) {
        SObjectType objType = record.getSObjectType();
        if(!type2Records.containsKey(objType)) {
            type2Records.put(objType, new List<SObject>());
        }
        type2Records.get(objType).add(record);
    }


    /**********************************************************************************************
    * @author                 Silvan Sholla
    * @date                   23/Oct/2019
    * @description            Utility Methods to get localisation information saved in cache
    **********************************************************************************************/
    //Start

    public class LocalisationCache implements Cache.CacheBuilder {
      public Object doLoad(String param) {
        List<RICSC_Localisation__c> locList = new List<RICSC_Localisation__c>();
        if(Schema.sObjectType.RICSC_Localisation__c.isAccessible()){
          locList = [SELECT Id, Name, RICSC_Maison__c, RICSC_LocalisationLevel__c, RICSC_ParentLocalisation__c, RICSC_ParentLocalisation__r.Name, RICSC_ParentLocalisation__r.RICSC_Maison__c
                FROM RICSC_Localisation__c];
        }
        return locList;
      }
    }

    private static Map<String,Id> mapLocalisationIds {
        get{
            if (mapLocalisationIds == null ) {
                initMaps();
            }

            return mapLocalisationIds;
        } private set;
    }

    private static Map<Id,RICSC_Localisation__c> mapLocalisationParent {
        get{
            if (mapLocalisationParent == null ) {
                initMaps();
            }

            return mapLocalisationParent;
        } private set;
    }

    public static Id getLocalisationId(String maisonAndCountry){

      String localisationId = mapLocalisationIds.get(maisonAndCountry);


      return localisationId;
    }

    public static Id getLocalisationId(String maison, String country){
        return getLocalisationId(maison+'.'+country);
    }

    public static RICSC_Localisation__c getLocalisationParent(Id localisationId){
        return mapLocalisationParent.get(localisationId);
    }

    private static void initMaps() {

      mapLocalisationIds = new Map<String,Id> ();
      mapLocalisationParent = new Map<Id, RICSC_Localisation__c> ();

		  for ( RICSC_Localisation__c  localisation : (List<RICSC_Localisation__c>) Cache.Org.get(Utility.LocalisationCache.class,'ALL') ){
            if(localisation.RICSC_LocalisationLevel__c == 'Country'){
                mapLocalisationIds.put(localisation.RICSC_Maison__c +'.'+localisation.Name,localisation.id);
            }

            mapLocalisationParent.put(localisation.Id, (RICSC_Localisation__c) localisation.getSObject('RICSC_ParentLocalisation__r'));
        }
    }

    //End

    /**********************************************************************************************
    * @author                 Maurizio D'Antonio
    * @date                   05/Nov/2019
    * @description            Method used to get MaisonsConfiguration__mdt metadata in a map where
                              the maison is the key
    * @return                 Map with the maison as a key and the related mdt as value
    **********************************************************************************************/
    public static Map<String, MaisonsConfiguration__mdt> getMaisonConfigurationMap(){
      List<MaisonsConfiguration__mdt> mdtList = [Select Maison__c, DirectProcessingTurnoverThreshold__c, DirectProcessingScoreThreshold__c FROM MaisonsConfiguration__mdt];
      Map<String, MaisonsConfiguration__mdt> maisonToConfigurationMap = new Map<String, MaisonsConfiguration__mdt>();
      for(MaisonsConfiguration__mdt mdt : mdtList){
        maisonToConfigurationMap.put(mdt.Maison__c, mdt);
      }
      return maisonToConfigurationMap;
    }

    /**********************************************************************************************
    * @author                 Piergiorgio Lisanti
    * @date                   27/Nov/2019
    * @description            Method used to sort a list Pairs (stringKey - decimalValue)
                              using bubble sort algorithm
    **********************************************************************************************/
    public static List<Pair> sortPairsList(List<Pair> oList){
        Decimal tmpValue = 0.00;
        String tmpKey = null;

        // Bubble sort
        for (Integer i = 0; i < oList.size()-1; i++) {
            for (Integer j = 1; j < oList.size(); j++) {
                if (oList.get(j-1).value > oList.get(j).value) {
                    // permute
                    tmpValue = oList.get(j-1).value;
                    tmpKey = oList.get(j-1).key;
                    oList.get(j-1).value = oList.get(j).value;
                    oList.get(j-1).key = oList.get(j).key;
                    oList.get(j).value = tmpValue;
                    oList.get(j).key = tmpKey;
                }
            }
        }

        return oList;
    }

    /**********************************************************************************************
    * @author                 Piergiorgio Lisanti
    * @date                   27/Nov/2019
    * @description            Given a map idToDecimalMap return a list Pair that can be used
                              for sorting purposes
    **********************************************************************************************/
    public static List<Pair> mapToListOfPairs(Map<String,Decimal> idToDecimalMap){
        List<Pair> pairLst = new List<Pair>();
        for(String id : idToDecimalMap.keySet()){
            pairLst.add(new Pair(id, idToDecimalMap.get(id)));
        }
        return pairLst;
    }

    public class Pair {
        public Decimal value { get; set; }
        public String key { get; set; }
        public Pair(String key,Decimal value) {
            this.value = value;
            this.key = key;
        }
    }

    /**********************************************************************************************
    * @author                 Piergiorgio Lisanti
    * @date                   27/Nov/2019
    * @description            Given 2 map<String,Decimal> with equal set of keys produce a third map whose values are
                              the product of corresponding values in the input maps
    **********************************************************************************************/
    public static Map<String,Decimal> getResultMapValuesMultiplied(Map<String,Decimal> map1,Map<String,Decimal> map2){
        Map<String,Decimal> resultMap = new Map<String,Decimal>();
        if(!map1.keySet().containsAll(map2.keySet())){
            throw new IllegalArgumentException('Maps have different keys');
        }
        for(String element : map1.keySet()){
            resultMap.put(element,map1.get(element)*map2.get(element));
        }
        return resultMap;
    }

    /**********************************************************************************************
    * @author                 Piergiorgio Lisanti
    * @date                   06/Jan/2020
    * @description            Return true if current thread is running in async context
    **********************************************************************************************/
    public static Boolean isAsync() {
        return System.isBatch() || System.isQueueable() || System.isScheduled() || System.isFuture();
    }
}