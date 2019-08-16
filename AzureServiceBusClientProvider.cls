public class AzureServiceBusClientProvider {
    
    string namespaceUri, sasKeyName, sasKey;
   
    public ServiceBusClientProvider(string namespace, string policyName, string key)
    {
        this.namespaceUri = 'https://' + namespace + '.servicebus.windows.net';
        this.sasKeyName = policyName;
        this.sasKey = key;
    }

    private static string createServiceBusOrEventHubsSASToken(string resourceUri, string sasKeyName, string sasKey) 
    {
        if (String.isBlank(resourceUri) 
            || String.isBlank(sasKeyName) 
            || String.isBlank(sasKey)) 
        {
            throw new MissingRequiredValueException('Missing required parameter');
        }
        string encoded = EncodingUtil.urlEncode(resourceUri, 'UTF-8');
        Integer minute = 60;
        Long ttl = Math.round(DateTime.now().getTime() / 1000) + minute;
        string signature = encoded + '\n' + ttl;
        string hash = generateHmacSHA256Signature(signature, sasKey);
        return 'SharedAccessSignature sr=' + encoded + '&sig=' +
            EncodingUtil.urlEncode(hash, 'UTF-8') + '&se=' + ttl + '&skn=' + sasKeyName;
    }
    
    private static String generateHmacSHA256Signature(String saltValue, String secretKeyValue) 
    {
        String algorithmName = 'HmacSHA256';
        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueOf(saltValue), Blob.valueOf(secretKeyValue));
        return EncodingUtil.base64Encode(hmacData);
    }
    
    public void SendMessageToTopic(string requestData, string topic)
    {
        if (String.isBlank(topic) ) 
        {
            throw new MissingRequiredValueException('Missing required parameter: topic');
        }
        System.debug('Topic: ' + topic);
        System.debug('Sending JSON: ' + requestData);
        
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(this.namespaceUri + '/' + topic + '/messages');
        request.setBody(requestData);
        request.setTimeout(120000);
        
        string token = createServiceBusOrEventHubsSASToken(namespaceUri, sasKeyName, sasKey);
        system.debug('Token: ' + token);
        request.setHeader('Authorization', token);
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        System.debug(request);
        HttpResponse response = http.send(request);
        System.debug(response);
    }
    
    public string PeekAndLockMessage(string subscriptionName, string topic)
    {
        if (String.isBlank(subscriptionName)
            || String.isBlank(topic) ) 
        {
            throw new MissingRequiredValueException('Missing required parameter');
        }
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(this.namespaceUri + '/' + topic + '/subscriptions/' + subscriptionName + '/messages/head');
        request.setTimeout(120000);
        
        string token = createServiceBusOrEventHubsSASToken(namespaceUri, sasKeyName, sasKey);
        system.debug('Token: ' + token);
        request.setHeader('Authorization', token);
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        System.debug(request);
        HttpResponse response = http.send(request);
        System.debug(response);
        
        return response.getBody();
    }

    public string ReceiveAndDelete(string subscriptionName, string topic)
    {
        if (String.isBlank(subscriptionName)
            || String.isBlank(topic) ) 
        {
            throw new MissingRequiredValueException('Missing required parameter');
        }
        HttpRequest request = new HttpRequest();
        request.setMethod('DELETE');
        request.setEndpoint(this.namespaceUri + '/' + topic + '/subscriptions/' + subscriptionName + '/messages/head');
        request.setTimeout(120000);
        
        string token = createServiceBusOrEventHubsSASToken(namespaceUri, sasKeyName, sasKey);
        system.debug('Token: ' + token);
        request.setHeader('Authorization', token);
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        System.debug(request);
        HttpResponse response = http.send(request);
        System.debug(response);
        
        return response.getBody();
    }

    
    public class MissingRequiredValueException extends Exception { }
}
