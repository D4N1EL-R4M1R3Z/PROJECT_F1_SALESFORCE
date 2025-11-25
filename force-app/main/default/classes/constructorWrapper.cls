public with sharing class constructorWrapper {
    public class root{
        public MRData MRData {set; get;}
    }
    public class MRData{
    
        public constructorTable constructorTable {set; get;}
    }
    public class  constructorTable{

        public String season {set; get;}
        public List<constructor> constructors {set; get;}
    }
    public class constructor{
        public String constructorId {set; get;}
        public String url {set; get;}
        public String name {set; get;}
        public String nationality {set; get;}
    }
}