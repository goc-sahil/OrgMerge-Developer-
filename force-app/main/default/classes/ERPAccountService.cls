@RestResource(urlMapping='/erp/account')
global with sharing class ERPAccountService {

    @HttpPost
    global static ResponseWrapper createAccount() {
        RestRequest req = RestContext.request;
        String body = req.requestBody == null ? '' : req.requestBody.toString();
        System.debug('ERP Account payload: ' + body);

        RestContext.response.statusCode = 201;
        ResponseWrapper resp = new ResponseWrapper();
        resp.status = 'SUCCESS';
        resp.message = 'ERP Account received';
        resp.timestamp = System.now();
        return resp;
    }

    global class ResponseWrapper {
        public String status;
        public String message;
        public Datetime timestamp;
    }
}