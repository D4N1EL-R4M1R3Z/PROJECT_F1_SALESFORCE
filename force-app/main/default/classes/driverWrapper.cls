public with sharing class driverWrapper {
    
public class root
    {
        public MRData MRData {set; get;}
    }
    public class MRData
    {
        public DriverTable DriverTable {set; get;}
    }
    public class DriverTable
    {
        public String season {set; get;}
        public List<Driver> Drivers {set; get;}
    }
    public class Driver
    {
        public String driverId {set; get;}
        public Integer permanentNumber {set; get;}
        public String code {set; get;}
        public String url {set; get;}
        public String givenName {set; get;}
        public String familyName {set; get;}
        public Date dateOfBirth {set; get;}     
        public String nationality {set; get;}
    }
        public class constructor{
        public String constructorId {set; get;}
        public String url {set; get;}
        public String name {set; get;}
        public String nationality {set; get;}
    }
}