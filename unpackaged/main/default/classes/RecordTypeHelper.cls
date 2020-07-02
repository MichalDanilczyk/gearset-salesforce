/******************************************************************************
*   @author         Piergiorgio
*   @date           26/Aug/2019
*   @description    RecordTypeHelper is an utility class used to facilitate access 
                    to RecordType Ids in a centralized and efficient way.
*                   Example usage:    RecordTypeHelper.getRTId('Account.Business')
*   @version        2.0
******************************************************************************/
public without sharing class RecordTypeHelper{
    
    @TestVisible private static final String CONCAT_STRING = '.';
    private static final String[] NAMESPACE_PREFIXES = new String[]{''};     //Add here namespaces of installed packages
    private static Map<String, Schema.SObjectType> globalDesc {
        get{
            if(globalDesc == null){ globalDesc = Schema.getGlobalDescribe(); }
            return globalDesc;
        } private set;
    } 
    
    /*
    *   Lazy loaded map with recordtype obj and developerName as key and recordType Ids as value
    */
    private static Map<String,Id> mapRecordTypesIds {
        get{
            if (mapRecordTypesIds == null ) {
                initMaps();
            }

            return mapRecordTypesIds;
        } private set;
    }
    
    
    private static Map<String, List<RecordType>> mapRecordTypes {
        get{
            if (mapRecordTypes == null ) {
                initMaps();
            }

            return mapRecordTypes;
        } private set;
    }
    
    private static void initMaps() {
        
        mapRecordTypesIds = new Map<String,Id> ();
        mapRecordTypes = new Map<String, List<RecordType>> ();

		for ( RecordType  rt : (List<RecordType>) Cache.Org.get(RecordTypeHelper.RecordTypeCache.class,'ALL') ){

            mapRecordTypesIds.put(rt.sobjectType + CONCAT_STRING + rt.developerName ,rt.id);
            
            if(mapRecordTypes.containsKey(rt.sobjectType)){
                mapRecordTypes.get(rt.sobjectType).add(rt);
            }else{
                mapRecordTypes.put(rt.sobjectType,new List<RecordType>{rt});
            }
        }
    
    }

    /**
    *   @description                        Returns the Id of the RecordType for the specified object and Record Type Developer Name   
    *   @param                              obj the API name of the object (es. Account or FinServ__FinancialAccount__c)
    *   @param RTDeveloperName              the developer name of the record type id requested (es. InsurancePolicy)
    *   @return                             the Id of the RT, if found
    *   @throws RecordTypeNotFoundException when obj and RTDeveloperName pair is not valid
    */
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.ApexDoc')
    public static Id getRTId(String obj, String RTDeveloperName){
        return getRTId(obj + CONCAT_STRING +RTDeveloperName);
    }

    /**
    *
    *   @description                        Returns the Id of the RecordType for the specified object 
    *                                       and Record Type Developer Name   
    *   @param objAndRTDeveloperName        the API name of the object concatenated  
    *                                       with the developerName of recordtype (with a '.' in between)
    *   @return                             the Id of the RT, if found
    *   @throws RecordTypeNotFoundException when objAndRTDeveloperName is not valid
    */
    @SuppressWarnings('PMD.ApexDoc')
    public static Id getRTId(String objAndRTDeveloperName){

        String recordTypeId = mapRecordTypesIds.get(objAndRTDeveloperName);

        if(recordTypeId == null){
            throw new RecordTypeNotFoundException(objAndRTDeveloperName + 'is not a valid object and recordType DeveloperName pair');
        }

        return recordTypeId;

    }
    
    /**
    *   @description                            Returns the List of RecordType for the specified object API Name  
    *   @param objAPIName                       the API name of the object
    *   @throws RecordTypeNotFoundException     when objAPIName is not valid
    *   @return                                 A list of RecordTypes available for input object
    */
    @SuppressWarnings('PMD.ApexDoc')
    public static List<RecordType> getRTList(String objAPIName){

        List<RecordType> recordTypeList = mapRecordTypes.get(objAPIName);

        if(recordTypeList != null && recordTypeList.size() > 0){
            return recordTypeList;
        }
        else if(globalDesc.containskey(objAPIName)){
            return new List<RecordType>();
        }
        else{
            throw new RecordTypeNotFoundException(objAPIName + 'is not a valid object API Name');
        }

    }
    
    /**
    *   @description    Utility Exception for not found RecordTypes  
    */
    public class RecordTypeNotFoundException extends Exception {}



    /**
    *   @description    If you ever need to refresh the cache: //new RecordTypeHelper.RecordTypeCache().doLoad('ALL'); 
    */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public class RecordTypeCache implements Cache.CacheBuilder {
        /**
        *   @description    override method to reload the cache
        *   @param  param   unused parameter
        *   @return Object  the result of the query reloading recordtypes
        */
        public Object doLoad(String param) {
            return [Select id, Name, developerName, sobjectType, IsActive, Description from RecordType where namespacePrefix in :RecordTypeHelper.NAMESPACE_PREFIXES];
        }

    }

}