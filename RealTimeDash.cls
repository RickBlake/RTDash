public class RealTimeDash {
    //multi select properties
    Public Id delFilterId {get;set;}
    Public List<string> leftselected{get;set;}
    Public List<string> rightselected{get;set;}
    Map<String,string> leftvalues = new Map<String,string>();
    Map<String,string>  rightvalues = new Map<String,string>();
    public boolean SelectedObject{get;set;}
    public List<Report_Criterion__c> Criteria {get;set;}
    public boolean showcolumns {get;set;}
    public List<SelectOption> OperatorsList{
        get{
            if(OperatorsList == null){
                OperatorsList = new List<SelectOption>{
                    new SelectOption('=','equals'),
                    new SelectOption('!=','not equal to'),
                    new SelectOption('<','less than'),
                    new SelectOption('>','greater than'),
                    new SelectOption('<=','less or equal'),
                    new SelectOption('>=','greater or equal'),
                    new SelectOption('contains','contains'),
                    new SelectOption('does not contain','does not contain'),
                    new SelectOption('starts with','starts with')
                };
            }
            return OperatorsList;
        }
        set;
    }
    public PageReference selectclick(){
        rightselected.clear();
        for(String s : leftselected){
            
            rightvalues.put(s,leftvalues.get(s));
            leftvalues.remove(s);
        }
        return null;
    }

    public PageReference AddFilter(){
       Criteria.add(new Report_Criterion__c());
       showcolumns=true;
       return null;
    }

    public PageReference DeleteFilter(){
        for(Integer i = 0; i < Criteria.size(); i++){
            if(Criteria[i].Id == delFilterId){
                Criteria.remove(i);
            }
        }
        return null;
    }

    public PageReference Save(){
        list<string> columns = new list<string>(rightvalues.keyset());
        RTDash.Report_Columns__c = String.join(columns,';');
        Database.UpsertResult result = Database.upsert(RTDash);
        for(Report_Criterion__c rc:Criteria){
            if(rc.Value__c != null && rc.Value__c != '' && rc.Real_Time_Dashboard__c == null){
                rc.Real_Time_Dashboard__c = result.getId();
            }
        }
        upsert Criteria;
        return null;
    }
    
    public PageReference unselectclick(){
        leftselected.clear();
        for(String s : rightselected){
            leftvalues.put(s,rightvalues.get(s));
            rightvalues.remove(s);
           
        }
        return null;
    }

    public List<SelectOption> AllOppFields {get;set;}
 
    public List<SelectOption> getunSelectedValues(){
        List<SelectOption> options = new List<SelectOption>();
        AllOppFields = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(leftvalues.keySet());
        tempList.sort();
        for(string s : tempList){

            options.add(new SelectOption(s,s));
            AllOppFields.add(new SelectOption(s,s));
        }
        return options;
    }
 
    public List<SelectOption> getSelectedValues(){
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues.keySet());
        if(tempList.size()>0){
        tempList.sort();
        for(String s : tempList)
            options1.add(new SelectOption(s,s));
        return options1;

        }
        return null;
    }

    //rt dash properties
    public Real_Time_Dash__c RTDash {get;set;}
    public string colsJSON {get;set;}
    public list<SelectOption> ObjectOptions{
        get{    
            if(ObjectOptions == null){  
                List<String> objectNames=new List<String>{'Account','Lead','Opportunity'}  ;
               // List<Schema.SObjectType> globalDesc = Schema.getGlobalDescribe().Values();     
                ObjectOptions = new List<SelectOption>();
                    ObjectOptions.add(new SelectOption('SELECT OBJECT','---------SELECT OBJECT-----------'));
                for(String s: objectNames){
                   ObjectOptions.add(new SelectOption(s,s));
                }
            }
            return ObjectOptions;
        }
        set;
    }

    public RealTimeDash(ApexPages.StandardController controller){
        this.RTDash = (Real_Time_Dash__c)controller.getRecord();
        this.Criteria = new List<Report_Criterion__c>();
        
        if(this.RTDash.Id != null){
            this.RTDash = [SELECT Id, Name, Report_Columns__c, Report_Object__c, 
                (SELECT Id, Real_Time_Dashboard__c, Field__c, Operator__c, Value__c FROM Report_Criteria__r) 
                FROM Real_Time_Dash__c 
                WHERE Id = :this.RTDash.Id];
            populateColSelect();
            if(this.RTDash.Report_Columns__c != null){
                for(string col : RTDash.Report_Columns__c.split(';')){
                    rightvalues.put(col,leftvalues.get(col));
                }
            }
           
            this.Criteria = this.RTDash.Report_Criteria__r;
            if(this.Criteria.size() > 0){
                showcolumns=true;
            }
        }
        system.debug(LoggingLevel.WARN, this.RTDash);
        if(RTDash.Report_Columns__c!=null){
            colsJSON = JSON.serialize(RTDash.Report_Columns__c.split(';'));
        }
        else{
            colsJSON=null;
        }
        
    }

    public PageReference populateColSelect(){
        SelectedObject=true;
        leftselected = new List<String>();
        rightselected = new List<String>();
        leftvalues = new Map<String,String>();
        list<Schema.SObjectField> fields = Schema.getGlobalDescribe().get(RTDash.Report_Object__c).getDescribe().fields.getMap().values();
        for(Schema.SObjectField f : fields){
           leftvalues.put(f.getDescribe().getName(),f.getDescribe().getLabel());
        }
        
        return null;
    }

    public String getRecords(){
        return JSON.serialize(Database.Query(RealTimeDash.getQuery(RTDash)));
    }

    private static string getQuery(Real_Time_Dash__c rtDash){
        string query = 'SELECT ';
        for(string col : rtDash.Report_Columns__c.split(';')){
            query += col + ',';
        }
        //remove trailing comma
        system.debug(LoggingLevel.WARN,'rt report query = ' + query);
        query = query.substring(0, query.lastIndexOf(','));
        query += ' FROM ';
        query += rtDash.Report_Object__c;
        if(rtDash.Report_Criteria__r.size() > 0){
            query += ' WHERE ';
            for(Report_Criterion__c rc:rtDash.Report_Criteria__r){
                query += rc.Field__c + ' ' + rc.Operator__c + ' \'' + rc.Value__c + '\',';
            }
        }
        //remove trailing comma
        query = query.substring(0, query.lastIndexOf(','));
        system.debug(LoggingLevel.WARN,'rt report query = ' + query);
        return query;
    }
    
    private static string getOppQuery(){
        string query = 'SELECT Id, Name, StageName FROM Opportunity ';
        return query;
    }

    private static string getLeadsQuery(){
        string query = 'SELECT Company, LeadSource, Division__c, Feature_Country__c, Website, Status FROM Lead ';
        query += 'WHERE IsConverted = false ';
        query += 'AND (CreatedDate = LAST_N_DAYS:10 OR Last_Phone_Bank_Call_Date__c = LAST_N_DAYS:10 OR Sourced_Date__c = LAST_N_DAYS:10) ';
        query += 'AND Category_v3__c = \'Food & Drink\' ';
        query += 'AND (LeadSource NOT IN (\'Web to Lead\',\'Lead Gen Team\',\'Rewards Marketing Page\',\'Phone Bank\',\'Comp Intel\',\'POS - Web to Lead\',\'POS - Phone Bank\',\'GW Question\',\'Competitor\',\'Inbound Team\',\'Merchant Center\',\'Web To Lead - Self Service\',\'Breadcrumb - Groupon Works\',\'Breadcrumb - BPOS Self Serve\',\'Breadcrumb - Website Self Serve\',\'Breadcrumb - Merchant Center Self Serve\',\'Breadcrumb - Referral Form\') ';
        query += 'OR Campaign_Name__c LIKE \'%k*%\' OR Campaign_Name__c LIKE \'%ppl%\')  ';
        query += 'AND Research_Ranking__c = null ';
        query += 'AND (Feature_Country__c = null OR Feature_Country__c = \'CA\' OR Feature_Country__c = \'US\') ';
        query += 'AND Division__c != \'Training\' ';
        system.debug(LoggingLevel.WARN, 'lead query = ' + query);
        return query;
    }
}