public without sharing class ModerationHandler {
    Map<String, Pattern> pMap = new Map<String, Pattern>(); // Block Patterns for each Moderation config
    Map<String, Pattern> eMap = new Map<String, Pattern>();  // Exception patterns for each Moderation config
    Map<String, String> mMap = new Map<String, String>(); // Message for each Moderation config
    Map<String, String> rMap = new Map<String, String>(); // Redact Pattern for each Moderation config

    public class ModerationResponse {
        private String key;
        private String status;
        private String redactedContent;

        public ModerationResponse(String inKey, String inStatus, String inRedactedContent) {
            key = inKey;
            status = inStatus;
            if (status == 'Redacted!') {
                redactedContent = inRedactedContent;
            }
        }

        public String getKey() {
            return this.key;
        }

        public String getStatus() {
            return this.status;
        }
        
        public String getRedactedContent() {
            return this.redactedContent;
        }
    }

    public ModerationHandler() {
        Integer i;
        String newLinePattern = '\r\n';
        for (Moderation_Block_Pattern__mdt bp : [select MasterLabel,
                                                        Block_REGEX_Patterns__c, 
                                                        Escape_Patterns__c,
                                                        Block_Message__c,
                                                        Redact_Pattern__c
                                                from 	Moderation_Block_Pattern__mdt
                                                where   IsActive__c = true]) {

            // Get block patterns
            newLinePattern = '\r\n';
            if (bp.Block_REGEX_Patterns__c != null) {
                i = 0;
                if (bp.Block_REGEX_Patterns__c.contains('\r\n')) {
                    newLinePattern = '\r\n';
                } else if (bp.Block_REGEX_Patterns__c.contains('\n')) {
                    newLinePattern = '\n';
                } else if (bp.Block_REGEX_Patterns__c.contains('\r')) {
                    newLinePattern = '\r';
                }
                for (String p : bp.Block_REGEX_Patterns__c.split(newLinePattern)) {
                    try {
                        pMap.put(bp.MasterLabel + ' (' + (++i) + ')', Pattern.compile(p));
                    } catch (Exception ex) {
                        throw new ModerationHandler.HandlerException('Error! Block Regex Pattern Compliation error: ' + bp.MasterLabel + '\n' + ex.getMessage());
                    }
                }
            }
            
            // Get escape patterns
            newLinePattern = '\r\n';
            if (bp.Escape_Patterns__c != null) {
                i = 0;
                if (bp.Escape_Patterns__c.contains('\r\n')) {
                    newLinePattern = '\r\n';
                } else if (bp.Escape_Patterns__c.contains('\n')) {
                    newLinePattern = '\n';
                } else if (bp.Escape_Patterns__c.contains('\r')) {
                    newLinePattern = '\r';
                }
                for (String e : bp.Escape_Patterns__c.split(newLinePattern)) {
                    try {
                        eMap.put(bp.MasterLabel + ' (' + (++i) + ')', Pattern.compile(e));
                    } catch (Exception ex) {
                        throw new ModerationHandler.HandlerException('Error! Escape Regex Pattern Compliation error: ' + bp.MasterLabel + '\n' + ex.getMessage());
                    }
                }
            }

            // Get custom block messages
            if (bp.Block_Message__c != null) {
                mMap.put(bp.MasterLabel, bp.Block_Message__c);
            }

            // Get redact patterns
            if (bp.Redact_Pattern__c != null) {
                rMap.put(bp.MasterLabel, bp.Redact_Pattern__c);
            }
        }
    }

    public Map<String, ModerationHandler.ModerationResponse> checkContent(Map<String, String> inputMap) {
        String inputContent;
        String redactedContent;
        String status;
        Boolean errorFound = false;
        String currentConfigLabel;
        Boolean exceptionFound = false;
        Map<String, ModerationHandler.ModerationResponse> returnMap = new Map<String, ModerationHandler.ModerationResponse>(); 

        // Check each input content from the map
        for (String c : inputMap.keySet()) {
            inputContent = inputMap.get(c);
            redactedContent = '';

            errorFound = false;
            exceptionFound = false;
            currentConfigLabel = '';
            status = 'OK';

            // Check for regex pattern match; 
            // Note: after first error the check stops for every input content
            // If no redaction specified, block pattern found & no exception pattern found, status set to 'Error!'
            // If Redacts are specified, entire input content is redacted after matching all block patterns & status will be set to Redacted!
            // while (k < patternKeys.size() && !errorFound) {
            for (String p : pMap.keySet()) {
                if (!errorFound) {
                    currentConfigLabel = p.split(' \\(')[0];

                    // if redact is required for this pattern, redact entire content
                    if (rMap.containsKey(currentConfigLabel)) {
                        redactedContent = redact(inputContent, pMap.get(p), rMap.get(currentConfigLabel));
                        if (redactedContent != inputContent && !String.isEmpty(redactedContent)) {
                            status = 'Redacted!';
                            inputContent = redactedContent;
                        }
                    }
                    // else search for block pattern & exception patterns 
                    else {
                        // First if there is a block pattern 
                        Matcher m = pMap.get(p).matcher(inputContent);
                        if (!errorFound && m.find()) {
                            // Find if exception found, then set warning message to status
                            Integer i = 1;
                            while (eMap.containsKey(currentConfigLabel + ' (' + i + ')') &&
                                    !exceptionFound) {
                                if (eMap.get(currentConfigLabel + ' (' + i + ')').matcher(inputContent).find()) {
                                    status = 'Warning! Found Exception for ' + currentConfigLabel + ' (' + i + ')';
                                    exceptionFound = true;
                                }
                                i++;
                            }

                            // If exception not found then set error message to status
                            if (!exceptionFound) {
                                status = 'Error! Found ' + p;

                                // If there is a custom message specified, add that to the status
                                if (mMap.get(currentConfigLabel) != null) {
                                    status += '\n' + mMap.get(currentConfigLabel);
                                }
                                errorFound = true;
                            }
                        }
                    }
                }
            }
            returnMap.put(c, new ModerationResponse(c, status, (status == 'Redacted!' ? inputContent : null)));
        }
        return returnMap;
    }

    public String redact(String inputString, Pattern inputPattern, String redactPattern) {
        String outputString = '';

        Matcher m = inputPattern.matcher(inputString);

        Integer prevIdx = 0;
        Integer startIdx;
        Integer endIdx;
        String patternMatch;
        String redactedString;
        while (m.find()) {
            // find the start and end indexes of the match
            startIdx = m.start();
            endIdx = m.end();
            patternMatch = inputString.substring(startIdx, endIdx);
            Integer j = 0;
            redactedString = '';
            for (Integer i = 0; i < redactPattern.length() && j < patternMatch.length(); i++) {
                if (redactPattern.substring(i,i+1) == '!') {
                    redactedString += patternMatch.substring(j,j+1);
                    ++j;
                } else if (redactPattern.substring(i,i+1) == 'X') {
                    redactedString += 'X';
                    ++j;
                } else {
                    redactedString += redactPattern.substring(i,i+1);
                }    
            }
            outputString += inputString.substring(prevIdx, startIdx) + redactedString;
            prevIdx = endIdx; 
        }

        if (prevIdx < inputString.length()-1) {
            outputString += inputString.substring(prevIdx);
        }

        return outputString;
    }

    public class HandlerException extends Exception { }
}
