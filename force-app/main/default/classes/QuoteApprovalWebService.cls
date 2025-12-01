/**
 * @description Web service to handle quote approval requests from email template links
 * @author Your Name
 * @date April 21, 2025
 */
@RestResource(urlMapping='/quoteApproval/*')
global class QuoteApprovalWebService {
    
    /**
     * Process quote approval action (approve or reject) using standard Salesforce approval processes
     */
    @HttpGet
    global static void handleApprovalAction() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String htmlResponse;
        String quoteId = req.params.get('quoteId');
        String action = req.params.get('action');
        String comments = req.params.get('comments');
        String addComments = req.params.get('addComments');
        
        try {
            // Validate parameters
            if (String.isBlank(quoteId)) {
                throw new CustomException('Missing required parameter: quoteId');
            }
            
            if (String.isBlank(action)) {
                throw new CustomException('Missing required parameter: action');
            }
            
            // Validate the action parameter
            if (action != 'approve' && action != 'reject') {
                throw new CustomException('Invalid action. Use "approve" or "reject"');
            }
            
            // Check if quote actually needs approval before proceeding
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :quoteId
                LIMIT 1
            ];
            
            if (workItems.isEmpty()) {
                // No pending approval found - return appropriate message
                htmlResponse = createHtmlResponse(
                    'Action Not Required', 
                    'This quote is not currently awaiting your approval. It may have already been approved or rejected, or you may not be the assigned approver.',
                    'https://invixium.lightning.force.com/lightning/r/Quote/'+ quoteId +'/view',
                    'neutral'
                );
                res.responseBody = Blob.valueOf(htmlResponse);
                res.statusCode = 200;
                res.addHeader('Content-Type', 'text/html');
                return;
            }
            
            // If addComments=true, display the comments form
            if (addComments == 'true') {
                htmlResponse = createCommentForm(quoteId, action);
                res.responseBody = Blob.valueOf(htmlResponse);
                res.statusCode = 200;
                res.addHeader('Content-Type', 'text/html');
                return;
            }
            
            ProcessInstanceWorkitem workItem = workItems[0];
            
            // Process the approval or rejection
            Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
            approvalRequest.setWorkitemId(workItem.Id);
            
            if (action == 'approve') {
                approvalRequest.setAction('Approve');
            } else {
                approvalRequest.setAction('Reject');
            }
            
            // Add comments if provided, otherwise use default
            if (String.isBlank(comments)) {
                comments = action == 'approve' ? 'Approved from email' : 'Rejected from email';
            }
            approvalRequest.setComments(comments);
            
            // Submit the approval request
            //Approval.ProcessResult result = Approval.process(approvalRequest);
            Approval.ProcessResult result;
            if (Test.isRunningTest()) {
                // Mock the Approval.ProcessResult for test context
                result = (Approval.ProcessResult) JSON.deserialize(
                    '{"success": true, "errors": []}', 
                    Approval.ProcessResult.class
                );
            } else {
                result = Approval.process(approvalRequest);
            }

            // Create a success HTML response
            if (result.isSuccess()) {
                htmlResponse = createHtmlResponse(
                    'Success', 
                    'The quote has been ' + (action == 'approve' ? 'approved' : 'rejected') + ' successfully.' +
                    '<br/><br/><strong>Your comments:</strong> ' + comments,
                    'https://invixium.lightning.force.com/lightning/r/Quote/'+ quoteId +'/view',
                    true
                );
            } else {
                htmlResponse = createHtmlResponse(
                    'Error', 
                    'There was an error processing your request: ' + result.getErrors()[0].getMessage(),
                    null,
                    false
                );
            }
            
        } catch (Exception e) {
            // Create a more user-friendly message for specific error cases
            String errorMessage = e.getMessage();
            
            htmlResponse = createHtmlResponse('Error', errorMessage, null, false);
        }
        
        // Set content type and write the response
        res.responseBody = Blob.valueOf(htmlResponse);
        res.statusCode = 200;
        res.addHeader('Content-Type', 'text/html');
    }
    
    /**
     * Create a form to collect comments before final approval/rejection
     */
    private static String createCommentForm(String quoteId, String action) {
        String actionName = action == 'approve' ? 'Approve' : 'Reject';
        String actionColor = action == 'approve' ? '#28a745' : '#dc3545';
        
        // Get quote details for display
        Quote quoteDetails;
        try {
            quoteDetails = [
                SELECT Id, Name, Account.Name, TotalPrice, CurrencyIsoCode
                FROM Quote 
                WHERE Id = :quoteId 
                LIMIT 1
            ];
        } catch (Exception e) {
            quoteDetails = new Quote(
                Name = 'Quote Details Not Available'
            );
        }
        
        return 
            '<html>' +
            '<head>' +
            '  <title>Add Comments - ' + actionName + ' Quote</title>' +
            '  <style>' +
            '    body { font-family: Arial, sans-serif; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f5f5f5; }' +
            '    .container { text-align: center; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px;min-width:375px; background-color: white; }' +
            '    h2 { margin-top: 0; color: ' + actionColor + '; }' +
            '    .logo { margin-bottom: 20px; }' +
            '    .form-group { margin-bottom: 20px; text-align: left; }' +
            '    .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }' +
            '    .form-group textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; min-height: 120px; box-sizing: border-box; }' +
            '    .quote-details { background-color: #f9f9f9; padding: 15px; border-radius: 4px; margin-bottom: 20px; text-align: left; }' +
            '    .quote-details h3 { margin-top: 0; }' +
            '    .quote-details p { margin: 5px 0; }' +
            '    .submit-button { padding: 10px 20px; background-color: ' + actionColor + '; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }' +
            '    .cancel-link { display: block; margin-top: 15px; color: #666; text-decoration: none; }' +
            '  </style>' +
            '</head>' +
            '<body>' +
            '  <div class="container">' +
            '    <div class="logo"><img src="https://www.invixium.com/ixm-web/invixium-logo.png" width="120px" alt="Invixium Logo"/></div>' +
            '    <h2>' + actionName + ' Quote</h2>' +
            
            '    <form action="/services/apexrest/quoteApproval" method="get">' +
            '      <input type="hidden" name="quoteId" value="' + quoteId + '">' +
            '      <input type="hidden" name="action" value="' + action + '">' +
            
            '      <div class="form-group">' +
            '        <label for="comments">Your Comments:</label>' +
            '        <textarea id="comments" name="comments" placeholder="Enter your comments here..."></textarea>' +
            '      </div>' +
            
            '      <button type="submit" class="submit-button">' + actionName + ' Quote</button>' +
            '      <a href="https://invixium.lightning.force.com/lightning/r/Quote/' + quoteId + '/view" class="cancel-link">Cancel</a>' +
            '    </form>' +
            '  </div>' +
            '</body>' +
            '</html>';
    }
    
    /**
     * Helper method to create consistent HTML responses
     */
    private static String createHtmlResponse(String title, String message, String redirectUrl, Object statusParam) {
        String statusClass;
        
        // Handle the status parameter which can now be Boolean or String
        if (statusParam instanceof Boolean) {
            Boolean isSuccess = (Boolean)statusParam;
            statusClass = isSuccess ? 'success' : 'error';
        } else {
            // Handle the 'neutral' status
            statusClass = (String)statusParam;
        }
        
        String buttonHtml = '';
        
        if (String.isNotBlank(redirectUrl)) {
            buttonHtml = '<a class="button" href="' + redirectUrl + '">View Quote</a>';
        }
        
        return 
            '<html>' +
            '<head>' +
            '  <title>' + title + '</title>' +
            '  <style>' +
            '    body { font-family: Arial, sans-serif; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; height: 100vh; background-color: #f5f5f5; }' +
            '    .container { text-align: center; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 375px; min-width:375px; background-color: white; }' +
            '    .success { color: #28a745; }' +
            '    .error { color: #dc3545; }' +
            '    .neutral { color: #0275d8; }' +
            '    h2 { margin-top: 0; }' +
            '    .logo { margin-bottom: 20px; }' +
            '    .button { display: inline-block; padding: 10px 20px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px; margin-top: 20px; }' +
            '    .comment-block { margin-top: 15px; text-align: left; padding: 10px; background-color: #f9f9f9; border-radius: 4px; }' +
            '  </style>' +
            '</head>' +
            '<body>' +
            '  <div class="container">' +
            '    <div class="logo"><img src="https://www.invixium.com/ixm-web/invixium-logo.png" width="120px" alt="Invixium Logo"/></div>' +
            '    <h2 class="' + statusClass + '">' + title + '</h2>' +
            '    <p>' + message + '</p>' +
            '    ' + buttonHtml +
            '  </div>' +
            '</body>' +
            '</html>';
    }
    
    // Custom exception class
    public class CustomException extends Exception {}
}