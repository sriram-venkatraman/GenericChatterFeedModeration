__Deploy to Dev Org/Prod:__ [![Deploy to Salesforce](https://andrewfawcett.files.wordpress.com/2014/09/deploy.png)](https://githubsfdeploy.herokuapp.com/app/githubdeploy/sriram-venkatraman/GenericChatterFeedModeration)

__Deploy to Sandbox:__ [![Deploy to Salesforce](https://andrewfawcett.files.wordpress.com/2014/09/deploy.png)](https://githubsfdeploy-sandbox.herokuapp.com/app/githubdeploy/sriram-venkatraman/GenericChatterFeedModeration)

## Sample Callout
```
ModerationHandler mh = new ModerationHandler();
Map<String, String> cs = new Map<String, String>();
cs.put('1', 'wer holycow ASDQE');
cs.put('2', 'wer 4123456789012345 ASDQE');
cs.put('3', 'wer awerw ASDQE');
cs.put('4', 'wer 06/02/1965 ASDQE');
cs.put('5', 'wer 06/02/1965(!dob) ASDQE');
cs.put('6', 'wer 398456789 ASDQE');
cs.put('7', 'wer 398456789(!ssn) ASDQE');

Map<String, ModerationHandler.ModerationResponse> output = mh.checkContent(cs);
for (String key : output.keySet()) {
    ModerationHandler.ModerationResponse mr = output.get(key);
    System.Debug('Key: ' + mr.getKey() + '\n' +
    			 'Status: ' + mr.getStatus() + '\n' +
        		 'Redacted Content: ' + mr.getRedactedContent() + '\n' +
                 '-------------------------------');
}
```

# Salesforce App

## Dev, Build and Test

## Resources

## Description of Files and Directories

## Issues
