public with sharing class constructorstandingWrapper {
  
    public class root
    {
        public MRData MRData {set; get;}
    }
    public class MRData 
    {
        public StandingsTable StandingsTable {set; get;}
    }
    public class StandingsTable 
    {
        public String season {set; get;}
        public String round {set; get;}
        public List<StandingsLists> StandingsLists {set; get;}
    }
    public class StandingsLists
    {
        public String season {set; get;}
        public String round {set; get;}
        public List<ConstructorStandings> ConstructorStandings {set; get;}
    }
    public class ConstructorStandings
    {
        public String position {set; get;}
        public String positionText {set; get;}
        public String points {set; get;}
        public String wins {set; get;}
        public Constructor Constructor {set; get;}
    }
    public class Constructor{
        
        public String constructorId {get; set;}
        public String url {get; set;}
        public String name {get; set;}
        public String nationality {get; set;}
    }

    
}