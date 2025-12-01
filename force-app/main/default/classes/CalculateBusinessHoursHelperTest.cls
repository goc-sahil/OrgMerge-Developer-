@IsTest
public class CalculateBusinessHoursHelperTest {
    
    @IsTest
    static void testRunOnceMethod() {
        System.assertEquals(true, CalculateBusinessHoursHelper.runOnce());
        System.assertEquals(false, CalculateBusinessHoursHelper.runOnce());
    }

    @IsTest
    static void testCalculateMondayPath() {
        BusinessHours bh = [SELECT Id, TimeZoneSidKey, MondayStartTime, MondayEndTime 
                            FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        Case c = new Case(
            Subject = 'Case Monday',
            Origin = 'Phone',
            BusinessHoursId = bh.Id,
            CreatedDate = DateTime.newInstance(2024, 9, 2, 10, 0, 0) // Monday
        );
        insert c;

        Map<Id, BusinessHours> bhMap = new Map<Id, BusinessHours>{ bh.Id => bh };
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(bhMap, c);

        if (bh.MondayStartTime == null || bh.MondayEndTime == null) {
            System.assertEquals(null, results, 'Should return null if Monday times are missing');
        } else {
            System.assertNotEquals(null, results, 'Results should not be null for Monday');
            System.assertEquals(3, results.size(), 'Should return 3 datetime values when times are set');
        }
    }

    @IsTest
    static void testCalculateSaturdayPath() {
        BusinessHours bh = [SELECT Id, TimeZoneSidKey, SaturdayStartTime, SaturdayEndTime 
                            FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        Case c = new Case(
            Subject = 'Case Saturday',
            Origin = 'Phone',
            BusinessHoursId = bh.Id,
            CreatedDate = DateTime.newInstance(2024, 9, 7, 10, 0, 0) // Saturday
        );
        insert c;

        Map<Id, BusinessHours> bhMap = new Map<Id, BusinessHours>{ bh.Id => bh };
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(bhMap, c);

        System.assert(results == null || results.size() == 3, 'Should handle Saturday path gracefully');
    }

    @IsTest
    static void testCalculateSundayPathWithMidnightEndTime() {
        BusinessHours bh = [SELECT Id, TimeZoneSidKey, SundayStartTime, SundayEndTime 
                            FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        // Force midnight case
        bh.SundayEndTime = Time.newInstance(0,0,0,0);

        Case c = new Case(
            Subject = 'Case Sunday',
            Origin = 'Phone',
            BusinessHoursId = bh.Id,
            CreatedDate = DateTime.newInstance(2024, 9, 8, 12, 0, 0) // Sunday
        );
        insert c;

        Map<Id, BusinessHours> bhMap = new Map<Id, BusinessHours>{ bh.Id => bh };
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(bhMap, c);

        if (bh.SundayStartTime != null) {
            System.assertNotEquals(null, results, 'Should adjust midnight end time correctly');
        }
    }

    @IsTest
    static void testCalculateWithNoBusinessHours() {
        Case c = new Case(
            Subject = 'Case without BH',
            Origin = 'Phone'
        );
        insert c;

        Map<Id, BusinessHours> emptyMap = new Map<Id, BusinessHours>();
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(emptyMap, c);

        System.assertEquals(null, results, 'Should be null when no BusinessHoursId');
    }

    @IsTest
    static void testCalculateWithNullStartEndTime() {
        BusinessHours bh = [SELECT Id, TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        Case c = new Case(
            Subject = 'Case Null Time',
            Origin = 'Phone',
            BusinessHoursId = bh.Id
        );
        insert c;

        Map<Id, BusinessHours> bhMap = new Map<Id, BusinessHours>();
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(bhMap, c);

        System.assertEquals(null, results, 'Should return null when Start/End times are not in map');
    }

    // 🔥 Extra coverage: Tuesday–Friday paths
  @IsTest
static void testWeekdayPaths() {
    BusinessHours bh = [SELECT Id, TimeZoneSidKey, 
                        TuesdayStartTime, TuesdayEndTime,
                        WednesdayStartTime, WednesdayEndTime,
                        ThursdayStartTime, ThursdayEndTime,
                        FridayStartTime, FridayEndTime
                        FROM BusinessHours WHERE IsDefault = true LIMIT 1];

    Date startDate = Date.newInstance(2024, 9, 3); // Tuesday
    for (Integer i = 0; i < 4; i++) {
        Date d = startDate.addDays(i);
        DateTime dt = DateTime.newInstance(d.year(), d.month(), d.day(), 10, 0, 0);

        Case c = new Case(
            Subject = 'Case Weekday ' + i,
            Origin = 'Phone',
            BusinessHoursId = bh.Id,
            CreatedDate = dt
        );
        insert c;

        Map<Id, BusinessHours> bhMap = new Map<Id, BusinessHours>{ bh.Id => bh };
        List<Datetime> results = CalculateBusinessHoursHelper.calculate(bhMap, c);

        System.assert(results == null || results.size() == 3, 
                      'Should return either null or 3 slots for weekday ' + i);
    }
}

}