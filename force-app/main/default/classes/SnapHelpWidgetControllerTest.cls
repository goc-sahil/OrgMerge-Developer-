@isTest
public class SnapHelpWidgetControllerTest {

    @isTest
    static void testNullGetRemainingDays() {
        
        System.assertEquals(0, SnapHelpWidgetController.getRemainingDays());
    }
}