@isTest
private class Utility_Test {

    @isTest static void testMyUserAndPrivileges(){

        system.assert(Utility.myUser.Id == UserInfo.getUserId());

        User admin = UtilityTests.getUser('System Administrator');
        System.runAs(admin){
            system.assert(true == Utility.hasAdminPrivileges, 'Admin profile should have Admin Custom Permission assigned');
            system.assertEquals(false,Utility.hasIntegrationPrivileges);
        }

    }

    @isTest static void testUtilityMethods(){

        //Sobjects getMap tests
        List<Account> accountList = new List<Account>
        {
            new Account (Id = '0010O000000ZWbNUAW', Name = 'John', Website = 'www.test.com'),
            new Account (Id = '0010O000000ZWbNUAH', Name = 'Anna', Website = 'www.test2.com')
        };

        Map<String,SObject> accountMap = Utility.getMap(accountList, 'Name');

        for(String accName : accountMap.keySet()){
            system.assertEquals(accName, accountMap.get(accName).get('Name'));
        }

        Map<String,SObject> accountMap2 = Utility.getMap(accountList, new List<String>{'Name','Website'}, new List<String>{'_'});

        for(String key : accountMap2.keySet()){
            system.assertEquals(key, accountMap2.get(key).get('Name')+'_'+accountMap2.get(key).get('Website'));
        }



        //Aggregate Result getMap tests

        insert UtilityTests.getAccount();

        List<AggregateResult> arList = [SELECT Name, COUNT(Id) childsCount FROM Account  GROUP BY Name ];

        Map<String,AggregateResult> arMap = Utility.getMap(arList, 'Name');

        for(String parentId : arMap.keySet()){
            system.assertEquals(parentId, arMap.get(parentId).get('Name'));
        }


        //GetSetOfIds tests

        Set<Id> accountIds = Utility.getSetOfIds(accountList,'Id');
        for(Account acc : accountList){
            system.assertEquals(true, accountIds.contains(acc.Id));
        }

    }

    @isTest static void getFieldSetAsStringTest(){

        Schema.FieldSet fs = Schema.SObjectType.User.fieldSets.MyUser_Fields;

        String res = Utility.getFieldSetAsString(fs, 'prefix.');
        List<String> resList = res.split(',');

        for(Schema.FieldSetMember fsm : fs.getFields()){

            System.assert(resList.contains('prefix.'+fsm.getFieldPath()), 'Each field of the fieldset should be part of the string');

        }

    }

    @isTest static void addToMapByKeyTest(){

        List<Account> accountList = new List<Account>
        {
            new Account (Id = '0010O000000ZWbNUAW', Name = 'John', Website = 'www.test.com', ParentId = '0010O000000ZWbNUAP'),
            new Account (Id = '0010O000000ZWbNUAH', Name = 'Anna', Website = 'www.test2.com', ParentId = '0010O000000ZWbNUAP')
        };

        Map<String, List<Account>> accountMap = new Map<String, List<Account>>();
        Map<SObject, List<Account>> accountMapObj = new Map<SObject, List<Account>>();


        for(Integer i = 0; i< accountList.size(); i++){

            Account acc = accountList[i];

            Utility.addToMapByKey(acc, Schema.Account.ParentId, accountMap);

            system.assertEquals(true, accountMap.containsKey(acc.ParentId));
            system.assertEquals(acc.Id, accountMap.get(acc.ParentId)[i].Id);

            Utility.addToMapByKey(acc, Schema.Account.ParentId, accountMapObj, Type.forName('Account'));

            Account parent = new Account(Id = '0010O000000ZWbNUAP');
            system.assertEquals(true, accountMapObj.containsKey(parent));
            system.assertEquals(acc.Id, accountMapObj.get(parent)[i].Id);


        }


    }


    @isTest static void extendJSONObjectTest(){

        String res = Utility.extendJSONObject('{"FirstName":"John"}', 'LastName', 'Fisher');
        Map<String,Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res);
        System.assertEquals('John', resMap.get('FirstName'));
        System.assertEquals('Fisher', resMap.get('LastName'));

    }

    @isTest static void staticResourceToJsonObjectTest() {

        String res = Utility.staticResourceToJsonObject('Configuration_ClassToScheduleJson');
        List<DeployScript.CronTriggerConf> cfcList =
            (List<DeployScript.CronTriggerConf>) JSON.deserialize(res,List<DeployScript.CronTriggerConf>.class);
        system.assert(cfcList != null, 'Deserialize NOT completed correctly');

    }


    @isTest static void staticResourceCSVToListOfSobjectTest() {
        //List<Account> rps = (List<Account>) Utility.staticResourceCSVToListOfSobject('Configuration_Account');
        //system.assert(rps.size()!=0);
        //TODO Complete
        system.assertEquals(1,1);
    }

}