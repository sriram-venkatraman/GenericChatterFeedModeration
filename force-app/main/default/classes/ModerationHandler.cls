public without sharing class ModerationHandler {
    Map<String, Pattern> pMap = new Map<String, Pattern>();
    Map<String, String> wMap = new Map<String, String>();

    public ModerationHandler() {
        Integer i;
        for (Moderation_Block_Pattern__mdt bp : [select MasterLabel,
                                                        Block_REGEX_Patterns__c, 
                                                        Block_Words__c
                                                from 	Moderation_Block_Pattern__mdt
                                                where  IsActive__c = true]) {
            
            if (bp.Block_Words__c != null) {
                if (bp.Block_Words__c.contains('\r\n')) {
                    for (String w : bp.Block_Words__c.split('\r\n')) {
                        system.debug('>W: ' + w);
                        wMap.put(bp.MasterLabel + ' (' + w + ')', w.remove(' '));
                    }
                } else if (bp.Block_Words__c.contains('\n')) {
                    for (String w : bp.Block_Words__c.split('\n')) {
                        system.debug('>W: ' + w);
                        wMap.put(bp.MasterLabel + ' (' + w + ')', w.remove(' '));
                    }
                } else if (bp.Block_Words__c.contains('\r')) {
                    for (String w : bp.Block_Words__c.split('\r')) {
                        system.debug('>W: ' + w);
                        wMap.put(bp.MasterLabel + ' (' + w + ')', w.remove(' '));
                    }
                }
            }
                                                    
            if (bp.Block_REGEX_Patterns__c != null) {
                i = 0;
                if (bp.Block_REGEX_Patterns__c.contains('\r\n')) {
                    for (String p : bp.Block_REGEX_Patterns__c.split('\r\n')) {
                        system.debug('>P: ' + p);
                        pMap.put(bp.MasterLabel + ' (' + (++i) + ')', Pattern.compile(p));
                    }
                } else if (bp.Block_REGEX_Patterns__c.contains('\n')) {
                    for (String p : bp.Block_REGEX_Patterns__c.split('\n')) {
                        system.debug('>P: ' + p);
                        pMap.put(bp.MasterLabel + ' (' + (++i) + ')', Pattern.compile(p));
                    }
                } else if (bp.Block_REGEX_Patterns__c.contains('\r')) {
                    for (String p : bp.Block_REGEX_Patterns__c.split('\r')) {
                        system.debug('>P: ' + p);
                        pMap.put(bp.MasterLabel + ' (' + (++i) + ')', Pattern.compile(p));
                    }
                }
            }
        }
    }

    public Map<String, String> checkContent(Map<String, String> inputMap) {
        String spaceRemovedInput;
        String status;
        Boolean errorFound = false;
        Map<String, String> returnMap = new Map<String, String>(); 

        for (String c : inputMap.keySet()) {
            spaceRemovedInput = inputMap.get(c).remove(' ').remove('-');
            errorFound = false;
            status = 'OK';
            for (String w : wMap.keySet()) {
                if (!errorFound && spaceRemovedInput.containsIgnoreCase(wMap.get(w))) {
                    status = 'Error! Found ' + w;
                    errorFound = true;
                }
            }

            system.debug('*** ' + pMap.keySet());
            for (String p : pMap.keySet()) {
                if (!errorFound && pMap.get(p).matcher(spaceRemovedInput).matches()) {
                    status = 'Error! Found ' + p;
                    errorFound = true;
                }
            }
            
            returnMap.put(c, status);
        }
        return returnMap;
    }
}
