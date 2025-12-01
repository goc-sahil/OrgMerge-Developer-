public class PendingApprovalRecords {
	public static void processRecords(List<ProcessInstanceWorkitem> workItems, Map<Id, Account> accountMap, Map<Id, Quote> quoteMap) {
        for (ProcessInstanceWorkitem item : workItems) {
            String prefix = String.valueOf(item.ProcessInstance.TargetObjectId).substring(0, 3);
            if (prefix == '001' && accountMap.containsKey(item.ProcessInstance.TargetObjectId)) {
                Account acc = accountMap.get(item.ProcessInstance.TargetObjectId);
                // Process Account details
                System.debug('Processing Account: ' + acc.Name);
            } else if (prefix == '0Q0' && quoteMap.containsKey(item.ProcessInstance.TargetObjectId)) {
                Quote quo = quoteMap.get(item.ProcessInstance.TargetObjectId);
                // Process Quote details
                System.debug('Processing Quote: ' + quo.Name);
            }
        }
    }
}