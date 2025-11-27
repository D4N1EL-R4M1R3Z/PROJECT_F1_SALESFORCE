// Se realizo la creacion de el Wrapper con base en la estructura de el Json y como este tiene
// Codificado la informacion

public class driverstandingWrapper {
    public class root {
        public MRData MRData;
    }
    public class MRData{
        public StandingsTable StandingsTable { get; set; }
    }
    public class StandingsTable{
        public List<StandingsLists> StandingsLists { get; set; }
    }
    public class StandingsLists{
        public List<DriverStandings> DriverStandings { get; set; }
    }
    public class DriverStandings{
        public String position { get; set; }
        public String positionText { get; set; }
        public String points { get; set; }
        public String wins { get; set; }
        public Driver Driver { get; set; }
        public List<Construtor> Constructors { get; set; }
    }

    public class Driver{
        public String DriverId { get; set; }
        public integer permanentNumber { get; set; }
        public String code { get; set; }
        public String nationality { get; set; }
        public String url { get; set; }
        public String givenName { get; set; }
        public String familyName { get; set; }
        public String dateOfBirth { get; set; }
    }
    
    public class Construtor{
        public String constructorId { get; set; }
        public String url { get; set; }
        public String name { get; set; }
        public String nationality { get; set; }
    }
}