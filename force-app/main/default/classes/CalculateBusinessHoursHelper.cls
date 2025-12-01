public class CalculateBusinessHoursHelper {
    
    private static boolean run = true;
        public static boolean runOnce(){
        if(run){
         run=false;
         System.Debug('**True');
         return true;
         
        }else{
            System.Debug('**False');
            return run;
        }
    }
    
    public static List<datetime> calculate(Map<Id,BusinessHours> bhsMap, Case c){
        Datetime BizStart;
        Datetime BizEnd;
        Time StartTime;
        Time EndTime;
        BusinessHours bizHr = bhsMap.get(c.BusinessHoursId);
        //Get the day in the business Hours Timezone
        if(bizHr != null){
            String day = c.createdDate.format('EEEE',bizHr.TimeZoneSidKey);
            if (day=='Monday') {StartTime = bizHr.MondayStartTime; EndTime = bizHr.MondayEndTime;}
            if (day=='Tuesday') {StartTime = bizHr.TuesdayStartTime; EndTime = bizHr.TuesdayEndTime;}
            if (day=='Wednesday') {StartTime = bizHr.WednesdayStartTime; EndTime = bizHr.WednesdayEndTime;}
            if (day=='Thursday') {StartTime = bizHr.ThursdayStartTime; EndTime = bizHr.ThursdayEndTime;}
            if (day=='Friday') {StartTime = bizHr.FridayStartTime; EndTime = bizHr.FridayEndTime;}
            if (day=='Saturday') {StartTime = bizHr.SaturdayStartTime; EndTime = bizHr.SaturdayEndTime;}
            if (day=='Sunday') {StartTime = bizHr.SundayStartTime; EndTime = bizHr.SundayEndTime;}
            
            System.Debug('StartTime: '+StartTime +', EndTime: '+EndTime);
            
            if(StartTime == null || EndTime == null)
                return null;
            
            if (timeinMilliSeconds(EndTime) == 0)
                EndTime = Time.newInstance(23,59,59,999);
            
            //Find the gap betwee the GMT and BizHr Timezone
            Datetime bizdt = datetime.valueOf(c.createdDate.format('yyyy-MM-dd HH:mm:ss',bizHr.TimeZoneSidKey));
            Datetime GMTdt = datetime.valueOf(c.createdDate.format('yyyy-MM-dd HH:mm:ss','GMT'));
            Long gap = bizdt.gettime() - GMTdt.gettime();
            
            System.Debug('Gap: '+gap);
            
            //Find the bizHr start datetime and End datetime based on case createddate in GMT
            Datetime dDate = dateTime.newInstance(c.createdDate.getTime()+gap);
            BizStart = datetime.newInstance(datetime.newInstanceGMT(dDate.yearGMT(),dDate.monthGMT(),dDate.dayGMT()).gettime()+timeinMilliSeconds(startTime));
            BizEnd = datetime.newInstance(datetime.newInstanceGMT(dDate.yearGMT(),dDate.monthGMT(),dDate.dayGMT()).gettime()+timeinMilliSeconds(endTime));
            
            
            List<datetime> bizHours = new List<datetime>();
            bizHours.add(BizStart);
            bizHours.add(BizEnd);
            bizHours.add(dDate);
            
            System.Debug('BizStart: '+BizStart.format('yyyy-MM-dd HH:mm:ss','GMT'));
            System.Debug('BizEnd: '+BizEnd.format('yyyy-MM-dd HH:mm:ss','GMT'));
            System.Debug('CreatedDate: '+dDate.format('yyyy-MM-dd HH:mm:ss','GMT'));
            
            Return bizHours;
        }else{
            return null;
        }
    }
    
    private static Long timeinMilliSeconds(Time tm){
        return        
        tm.hour()*60*60*1000+
        tm.minute()*60*1000+
        tm.second()*1000+
        tm.millisecond();
    }
}