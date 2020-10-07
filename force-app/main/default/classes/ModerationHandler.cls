public without sharing class ModerationHandler {
    Map<String, Pattern> pMap = new Map<String, Pattern>();
    Map<String, Pattern> eMap = new Map<String, Pattern>();
    Map<String, String> wMap = new Map<String, String>();

    public ModerationHandler() {
        Integer i;
        String newLinePattern = '\r\n';
        for (Moderation_Block_Pattern__mdt bp : [select MasterLabel,
                                                        Block_REGEX_Patterns__c, 
                                                        Block_Words__c,
                                                        Escape_Patterns__c
                                                from 	Moderation_Block_Pattern__mdt
                                                where  IsActive__c = true]) {
            
            newLinePattern = '\r\n';
            if (bp.Block_Words__c != null) {
                if (bp.Block_Words__c.contains('\r\n')) {
                    newLinePattern = '\r\n';
                } else if (bp.Block_Words__c.contains('\n')) {
                    newLinePattern = '\n';
                } else if (bp.Block_Words__c.contains('\r')) {
                    newLinePattern = '\r';
                }
                for (String w : bp.Block_Words__c.split(newLinePattern)) {
                    wMap.put(bp.MasterLabel + ' (' + w + ')', w.remove(' '));
                }
            }
                         
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
        }
    }

    public Map<String, String> checkContent(Map<String, String> inputMap) {
        String spaceRemovedInput;
        String status;
        Boolean errorFound = false;
        String errorLabel;
        Boolean exceptionFound = false;
        Map<String, String> returnMap = new Map<String, String>(); 

        for (String c : inputMap.keySet()) {
            spaceRemovedInput = inputMap.get(c);
            errorFound = false;
            exceptionFound = false;
            errorLabel = '';
            status = 'OK';
            for (String w : wMap.keySet()) {
                if (!errorFound && spaceRemovedInput.containsIgnoreCase(wMap.get(w))) {
                    status = 'Error! Found ' + w;
                    errorFound = true;
                    errorLabel = w.split(' \\(')[0];
                }
            }

            for (String p : pMap.keySet()) {
                if (!errorFound && pMap.get(p).matcher(spaceRemovedInput).matches()) {
                    status = 'Error! Found ' + p;
                    errorFound = true;
                    errorLabel = p.split(' \\(')[0];
                }
            } 
            
            if (errorFound && errorLabel != '') {
                Integer i = 0;
                while (eMap.containsKey(errorLabel + ' (' + (++i) + ')') && !exceptionFound) {
                    if (eMap.get(errorLabel + ' (' + i + ')').matcher(spaceRemovedInput).matches()) {
                        status = 'Warning! Found Exception for ' + errorLabel + ' (' + i + ')';
                        exceptionFound = true;
                    }
                }
            }

            returnMap.put(c, status);
        }
        return returnMap;
    }

    public class HandlerException extends Exception { }
}
