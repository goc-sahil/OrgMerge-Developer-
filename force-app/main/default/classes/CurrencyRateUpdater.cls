public with sharing class CurrencyRateUpdater {
      @AuraEnabled
    public static String updateCurrencyRate(String isoCode, Decimal newRate) {
        try {
            // Step 1: Get CurrencyType Id
            CurrencyType currencyRec = [
                SELECT Id, IsoCode
                FROM CurrencyType
                WHERE IsoCode = :isoCode
                LIMIT 1
            ];

            if (currencyRec == null) {
                return 'Currency not found: ' + isoCode;
            }

            // Step 2: Get dynamic callout config from Custom Metadata / Custom Labels
            String instanceUrl = Label.Currency_API_InstanceURL; // Custom Label
            String clientId = Label.Currency_API_ClientId;       // Custom Label
            String clientSecret = Label.Currency_API_ClientSecret; // Custom Label
            

            // Step 3: Get Access Token dynamically
            String accessToken = getAccessToken(instanceUrl, clientId, clientSecret);

            if (String.isBlank(accessToken)) {
                return 'Failed to obtain access token';
            }

            // Step 4: Prepare composite request JSON
            Map<String, Object> compositeBody = new Map<String, Object>{
                'allOrNone' => false,
                'compositeRequest' => new List<Object>{
                    new Map<String, Object>{
                        'method' => 'PATCH',
                        'url' => '/services/data/v64.0/sobjects/CurrencyType/' + currencyRec.Id,
                        'referenceId' => 'updateCurrency',
                        'body' => new Map<String, Object>{ 'ConversionRate' => newRate }
                    }
                }
            };

            String requestBody = JSON.serialize(compositeBody);

            // Step 5: Make callout to Salesforce Composite API
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/data/v64.0/composite');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                return 'Currency rate updated successfully for ' + isoCode;
            } else {
                return 'Failed to update: ' + res.getBody();
            }

        } catch (Exception e) {
            return 'Exception: ' + e.getMessage();
        }
    }

    // Helper method to get OAuth access token dynamically
    private static String getAccessToken(String instanceUrl, String clientId, String clientSecret) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(instanceUrl + '/services/oauth2/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            String body = 'grant_type=client_credentials'
                        + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
                        + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');

            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (String) result.get('access_token');
            }
        } catch (Exception e) {
            System.debug('Error fetching access token: ' + e.getMessage());
        }
        return null;
    }
}