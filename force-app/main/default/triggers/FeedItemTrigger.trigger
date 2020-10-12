trigger FeedItemTrigger on FeedItem (before insert, before update) {

    ModerationHandler mh = new ModerationHandler();
    Map<String, String> fiInMap = new Map<String, String>();
    Map<String, ModerationHandler.ModerationResponse> fiOutMap;
    
    FeedItem fi;
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        fi = Trigger.new[i];
        if (!String.isEmpty(fi.Title)) {
            fiInMap.put(i.format(), fi.Title + '[__Title__]');
        }
        fiInMap.put(i.format(), fi.Body);
    }
    
    if (fiInMap.size() > 0) {
        fiOutMap = mh.checkContent(fiInMap);
    }
    
    for (String k : fiOutMap.keySet()) {
        ModerationHandler.ModerationResponse mr = fiOutMap.get(k);

        if (mr.getStatus().startsWith('Error!')) {
            Trigger.new[Integer.valueOf(k)].Body.addError(mr.getStatus());
        }
        if (mr.getStatus().startsWith('Warning!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'PendingReview';
        }
        if (mr.getStatus().startsWith('Redacted!')) {
            Trigger.new[Integer.valueOf(k)].Status = 'Published';
            String s = mr.getRedactedContent();
            if (s.endsWith('[__Title__]')) {
                Trigger.new[Integer.valueOf(k)].Title = s;
            } else {
                Trigger.new[Integer.valueOf(k)].Body = s;
            }
        }
        if (Trigger.isUpdate) {
            if (mr.getStatus() == 'OK' && Trigger.old[Integer.valueOf(k)].Status == 'PendingReview') {
                Trigger.new[Integer.valueOf(k)].Status = 'Published';
            }
        }
    }
    
}